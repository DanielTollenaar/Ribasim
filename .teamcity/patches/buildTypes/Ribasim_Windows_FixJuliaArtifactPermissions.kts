package patches.buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.BuildType
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.ui.*

/*
This patch script was generated by TeamCity on settings change in UI.
To apply the patch, create a buildType with id = 'Ribasim_Windows_FixJuliaArtifactPermissions'
in the project with id = 'Ribasim_Windows', and delete the patch script.
*/
create(RelativeId("Ribasim_Windows"), BuildType({
    id("Ribasim_Windows_FixJuliaArtifactPermissions")
    name = "Fix Julia Artifact permissions"
    description = "Temporary build to run on a failing agent"

    steps {
        script {
            name = "Reset permissions"
            id = "Reset_permissions"
            scriptContent = "icacls %teamcity.agent.jvm.user.home%/.julia/artifacts /q /c /t /reset"
        }
    }
}))

