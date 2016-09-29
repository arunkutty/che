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
package org.eclipse.che.ide.command.macro;

import com.google.inject.Inject;

import org.eclipse.che.ide.api.command.macro.CommandMacro;
import org.eclipse.che.ide.api.command.macro.CommandMacroRegistry;
import org.eclipse.che.ide.util.loging.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Implementation for {@link CommandMacroRegistry}.
 *
 * @author Artem Zatsarynnyi
 */
public class CommandMacroRegistryImpl implements CommandMacroRegistry {

    private final Map<String, CommandMacro> valueProviders;

    public CommandMacroRegistryImpl() {
        this.valueProviders = new HashMap<>();
    }

    @Inject(optional = true)
    public void register(Set<CommandMacro> valueProviders) {
        for (CommandMacro provider : valueProviders) {
            final String key = provider.getName();
            if (this.valueProviders.containsKey(key)) {
                Log.warn(CommandMacroRegistryImpl.class, "Command macro '" + key + "' is already registered.");
            } else {
                this.valueProviders.put(key, provider);
            }
        }
    }

    @Override
    public void unregister(CommandMacro valueProvider) {
        valueProviders.remove(valueProvider.getName());
    }

    @Override
    public CommandMacro getProvider(String key) {
        return valueProviders.get(key);
    }

    @Override
    public List<CommandMacro> getProviders() {
        return new ArrayList<>(valueProviders.values());
    }

    @Override
    public Set<String> getKeys() {
        return valueProviders.keySet();
    }
}