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
package org.eclipse.che.ide.api.command;

import org.eclipse.che.api.core.model.machine.Machine;
import org.eclipse.che.api.promises.client.Promise;
import org.eclipse.che.ide.api.command.macro.CommandMacro;

import java.util.List;
import java.util.Map;

/**
 * Facade for command related operations.
 *
 * @author Artem Zatsarynnyi
 */
public interface CommandManager {

    /** Returns all commands. */
    List<CommandImpl> getCommands();

    /**
     * Creates new command of the specified type.
     * <p><b>Note</b> that command's name will be generated by {@link CommandManager}
     * and command line will be provided by an appropriate {@link CommandType}.
     */
    Promise<CommandImpl> create(String type);

    /**
     * Creates new command with the specified arguments.
     * <p><b>Note</b> that name of the created command may differ from
     * the specified {@code desirableName} in order to prevent name duplication.
     */
    Promise<CommandImpl> create(String desirableName, String commandLine, String type, Map<String, String> attributes);

    /**
     * Updates the command with the specified {@code name} by replacing it with the given {@code command}.
     * <p><b>Note</b> that name of the updated command may differ from the name provided by the given {@code command}
     * in order to prevent name duplication.
     */
    Promise<CommandImpl> update(String name, CommandImpl command);

    /** Removes the command with the specified {@code name}. */
    Promise<Void> remove(String name);

    /** Returns the pages for editing command of the specified {@code type}. */
    List<CommandPage> getPages(String type);

    /** Returns all command producers. */
    List<CommandProducer> getCommandProducers();

    /**
     * Sends the the given {@code command} to the specified {@code machine} for execution.
     * <p><b>Note</b> that all {@link CommandMacro}s will be expanded into
     * real values before sending the {@code command} for execution.
     *
     * @param command
     *         command to execute
     * @param machine
     *         machine to execute the command
     * @see CommandMacro
     * @see #expandMacros(String)
     */
    void executeCommand(CommandImpl command, Machine machine);

    /**
     * Expands all macros in the given {@code commandLine}.
     * <p>If {@link CommandManager} is unable to find a macro, the macro will not be expanded.
     *
     * @see CommandMacro
     * @see #executeCommand(CommandImpl, Machine)
     */
    Promise<String> expandMacros(String commandLine);

    void addCommandChangedListener(CommandChangedListener listener);

    void removeCommandChangedListener(CommandChangedListener listener);

    /** Listener that will be called when command has been changed. */
    interface CommandChangedListener {
        void onCommandAdded(CommandImpl command);

        void onCommandUpdated(CommandImpl command);

        void onCommandRemoved(CommandImpl command);
    }
}
