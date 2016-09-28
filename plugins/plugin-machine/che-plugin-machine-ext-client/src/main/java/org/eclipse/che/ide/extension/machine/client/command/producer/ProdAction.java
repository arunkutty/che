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
package org.eclipse.che.ide.extension.machine.client.command.producer;

import com.google.inject.Inject;
import com.google.inject.Singleton;

import org.eclipse.che.ide.api.action.AbstractPerspectiveAction;
import org.eclipse.che.ide.api.action.ActionEvent;
import org.eclipse.che.ide.api.command.CommandManager;
import org.eclipse.che.ide.api.command.CommandImpl;
import org.eclipse.che.ide.api.command.CommandProducer;
import org.eclipse.che.ide.workspace.perspectives.project.ProjectPerspective;

import java.util.Collections;

@Singleton
public class ProdAction extends AbstractPerspectiveAction {

    private final CommandManager commandManager;

    private final CommandProducer commandProducer;

    @Inject
    public ProdAction(CommandManager commandManager) {
        super(Collections.singletonList(ProjectPerspective.PROJECT_PERSPECTIVE_ID), "prod", "", null, null);
        this.commandManager = commandManager;

        commandProducer = commandManager.getCommandProducers().get(0);
    }

    @Override
    public void updateInPerspective(ActionEvent event) {
        event.getPresentation().setEnabledAndVisible(commandProducer.isApplicable());

        event.getPresentation().setText(commandProducer.getName());
    }

    @Override
    public void actionPerformed(ActionEvent event) {
        CommandImpl command = commandProducer.createCommand();

        commandManager.create(command.getName(),
                              command.getCommandLine(),
                              command.getType(),
                              command.getAttributes());
    }
}
