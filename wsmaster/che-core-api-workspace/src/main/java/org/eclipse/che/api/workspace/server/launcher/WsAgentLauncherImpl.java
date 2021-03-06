/*******************************************************************************
 * Copyright (c) 2012-2016 Codenvy, S.A.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *   Codenvy, S.A. - initial API and implementation
 *******************************************************************************/
package org.eclipse.che.api.workspace.server.launcher;

import org.eclipse.che.api.agent.server.launcher.AgentLauncher;
import org.eclipse.che.api.agent.shared.model.Agent;
import org.eclipse.che.api.core.ApiException;
import org.eclipse.che.api.core.BadRequestException;
import org.eclipse.che.api.core.NotFoundException;
import org.eclipse.che.api.core.ServerException;
import org.eclipse.che.api.core.model.machine.Server;
import org.eclipse.che.api.core.rest.HttpJsonRequest;
import org.eclipse.che.api.core.rest.HttpJsonRequestFactory;
import org.eclipse.che.api.core.rest.HttpJsonResponse;
import org.eclipse.che.api.environment.server.MachineProcessManager;
import org.eclipse.che.api.machine.server.exception.MachineException;
import org.eclipse.che.api.machine.server.model.impl.CommandImpl;
import org.eclipse.che.api.machine.server.spi.Instance;
import org.eclipse.che.api.machine.shared.Constants;
import org.eclipse.che.commons.annotation.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import javax.inject.Named;
import javax.inject.Provider;
import javax.inject.Singleton;
import javax.ws.rs.HttpMethod;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.util.Map;

import static com.google.common.base.MoreObjects.firstNonNull;
import static org.eclipse.che.api.workspace.shared.Constants.WS_AGENT_PROCESS_NAME;

/**
 * Starts ws agent in the machine and waits until ws agent sends notification about its start.
 *
 * @author Alexander Garagatyi
 * @author Anatolii Bazko
 */
@Singleton
public class WsAgentLauncherImpl implements AgentLauncher {
    protected static final Logger LOG = LoggerFactory.getLogger(WsAgentLauncherImpl.class);

    private static final String WS_AGENT_PROCESS_OUTPUT_CHANNEL = "workspace:%s:ext-server:output";
    private static final String WS_AGENT_SERVER_NOT_FOUND_ERROR = "Workspace agent server not found in dev machine.";

    protected static final String DEFAULT_WS_AGENT_RUN_COMMAND = "~/che/ws-agent/bin/catalina.sh run";

    private final Provider<MachineProcessManager> machineProcessManagerProvider;
    private final HttpJsonRequestFactory          httpJsonRequestFactory;
    private final long                            wsAgentMaxStartTimeMs;
    private final long                            wsAgentPingDelayMs;
    private final int                             wsAgentPingConnectionTimeoutMs;
    private final String                          pingTimedOutErrorMessage;
    private final String wsAgentRunCommand;

    @Inject
    public WsAgentLauncherImpl(Provider<MachineProcessManager> machineProcessManagerProvider,
                               HttpJsonRequestFactory httpJsonRequestFactory,
                               @Nullable @Named("machine.ws_agent.run_command") String wsAgentRunCommand,
                               @Named("machine.ws_agent.max_start_time_ms") long wsAgentMaxStartTimeMs,
                               @Named("machine.ws_agent.ping_delay_ms") long wsAgentPingDelayMs,
                               @Named("machine.ws_agent.ping_conn_timeout_ms") int wsAgentPingConnectionTimeoutMs,
                               @Named("machine.ws_agent.ping_timed_out_error_msg") String pingTimedOutErrorMessage) {
        this.machineProcessManagerProvider = machineProcessManagerProvider;
        this.httpJsonRequestFactory = httpJsonRequestFactory;
        this.wsAgentMaxStartTimeMs = wsAgentMaxStartTimeMs;
        this.wsAgentPingDelayMs = wsAgentPingDelayMs;
        this.wsAgentPingConnectionTimeoutMs = wsAgentPingConnectionTimeoutMs;
        this.pingTimedOutErrorMessage = pingTimedOutErrorMessage;
        this.wsAgentRunCommand = wsAgentRunCommand;
    }

    @Override
    public String getAgentName() {
        return "org.eclipse.che.ws-agent";
    }

    @Override
    public String getMachineType() {
        return "docker";
    }

    @Override
    public void launch(Instance machine, Agent agent) throws ServerException {
        final HttpJsonRequest wsAgentPingRequest;
        try {
            wsAgentPingRequest = createPingRequest(machine);
        } catch (ServerException e) {
            throw new MachineException(e.getServiceError());
        }

        String script = agent.getScript() + "\n" + firstNonNull(wsAgentRunCommand, DEFAULT_WS_AGENT_RUN_COMMAND);

        final String wsAgentPingUrl = wsAgentPingRequest.getUrl();
        try {
            // for server side type of command mean nothing
            // but we will use it as marker on
            // client side for track this command
            CommandImpl command = new CommandImpl(getAgentName(), script, WS_AGENT_PROCESS_NAME);

            machineProcessManagerProvider.get().exec(machine.getWorkspaceId(),
                                                     machine.getId(),
                                                     command,
                                                     getWsAgentProcessOutputChannel(machine.getWorkspaceId()));

            final long pingStartTimestamp = System.currentTimeMillis();
            LOG.debug("Starts pinging ws agent. Workspace ID:{}. Url:{}. Timestamp:{}",
                      machine.getWorkspaceId(),
                      wsAgentPingUrl,
                      pingStartTimestamp);

            while (System.currentTimeMillis() - pingStartTimestamp < wsAgentMaxStartTimeMs) {
                if (pingWsAgent(wsAgentPingRequest)) {
                    return;
                } else {
                    Thread.sleep(wsAgentPingDelayMs);
                }
            }
        } catch (BadRequestException | ServerException | NotFoundException e) {
            throw new ServerException(e.getServiceError());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ServerException("Ws agent pinging is interrupted");
        }
        LOG.error("Fail pinging ws agent. Workspace ID:{}. Url:{}. Timestamp:{}", machine.getWorkspaceId(), wsAgentPingUrl);
        throw new ServerException(pingTimedOutErrorMessage);
    }

    public static String getWsAgentProcessOutputChannel(String workspaceId) {
        return String.format(WS_AGENT_PROCESS_OUTPUT_CHANNEL, workspaceId);
    }

    // forms the ping request based on information about the machine.
    protected HttpJsonRequest createPingRequest(Instance machine) throws ServerException {
        Map<String, ? extends Server> servers = machine.getRuntime().getServers();
        Server wsAgentServer = servers.get(Constants.WS_AGENT_PORT);
        if (wsAgentServer == null) {
            LOG.error("{} WorkspaceId: {}, DevMachine Id: {}, found servers: {}",
                      WS_AGENT_SERVER_NOT_FOUND_ERROR, machine.getWorkspaceId(), machine.getId(), servers);
            throw new ServerException(WS_AGENT_SERVER_NOT_FOUND_ERROR);
        }
        String wsAgentPingUrl = wsAgentServer.getProperties().getInternalUrl();
        // since everrest mapped on the slash in case of it absence
        // we will always obtain not found response
        if (!wsAgentPingUrl.endsWith("/")) {
            wsAgentPingUrl = wsAgentPingUrl.concat("/");
        }
        return httpJsonRequestFactory.fromUrl(wsAgentPingUrl)
                                     .setMethod(HttpMethod.GET)
                                     .setTimeout(wsAgentPingConnectionTimeoutMs);
    }

    private boolean pingWsAgent(HttpJsonRequest wsAgentPingRequest) throws ServerException {
        try {
            final HttpJsonResponse pingResponse = wsAgentPingRequest.request();
            if (pingResponse.getResponseCode() == HttpURLConnection.HTTP_OK) {
                return true;
            }
        } catch (ApiException | IOException ignored) {
        }
        return false;
    }
}
