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
package org.eclipse.che.ide.ext.java.client.command;

import com.google.inject.Inject;
import com.google.inject.Singleton;

import org.eclipse.che.ide.api.command.CommandPage;
import org.eclipse.che.ide.api.command.CommandType;
import org.eclipse.che.ide.api.icon.Icon;
import org.eclipse.che.ide.api.icon.IconRegistry;
import org.eclipse.che.ide.ext.java.client.JavaLocalizationConstant;
import org.eclipse.che.ide.ext.java.client.JavaResources;
import org.eclipse.che.ide.ext.java.client.command.valueproviders.ClasspathProvider;
import org.eclipse.che.ide.ext.java.client.command.valueproviders.OutputDirProvider;
import org.eclipse.che.ide.ext.java.client.command.valueproviders.SourcepathProvider;
import org.eclipse.che.ide.extension.machine.client.command.macros.CurrentProjectPathProvider;

import java.util.LinkedList;
import java.util.List;

/**
 * Java command type.
 *
 * @author Valeriy Svydenko
 */
@Singleton
public class JavaCommandType implements CommandType {

    private static final String ID = "java";

    private final CurrentProjectPathProvider currentProjectPathProvider;
    private final SourcepathProvider         sourcepathProvider;
    private final OutputDirProvider          outputDirProvider;
    private final ClasspathProvider          classpathProvider;
    private final JavaLocalizationConstant   localizationConstants;
    private final List<CommandPage>          pages;

    @Inject
    public JavaCommandType(JavaResources resources,
                           JavaCommandPagePresenter page,
                           CurrentProjectPathProvider currentProjectPathProvider,
                           SourcepathProvider sourcepathProvider,
                           OutputDirProvider outputDirProvider,
                           ClasspathProvider classpathProvider,
                           IconRegistry iconRegistry,
                           JavaLocalizationConstant localizationConstants) {
        this.currentProjectPathProvider = currentProjectPathProvider;
        this.sourcepathProvider = sourcepathProvider;
        this.outputDirProvider = outputDirProvider;
        this.classpathProvider = classpathProvider;
        this.localizationConstants = localizationConstants;
        pages = new LinkedList<>();
        pages.add(page);

        iconRegistry.registerIcon(new Icon(ID + ".commands.category.icon", resources.javaCategoryIcon()));
    }

    @Override
    public String getId() {
        return ID;
    }

    @Override
    public String getDisplayName() {
        return "Java";
    }

    @Override
    public String getDescription() {
        return localizationConstants.commandLineDescription();
    }

    @Override
    public List<CommandPage> getPages() {
        return pages;
    }

    @Override
    public String getCommandLineTemplate() {
        return "cd " + currentProjectPathProvider.getKey() +
               " && javac -classpath " + classpathProvider.getKey() +
               " -sourcepath " + sourcepathProvider.getKey() +
               " -d " + outputDirProvider.getKey() +
               " src/Main.java" +
               " && java -classpath " + classpathProvider.getKey() + outputDirProvider.getKey() +
               " Main";
    }

    @Override
    public String getPreviewUrlTemplate() {
        return "";
    }
}
