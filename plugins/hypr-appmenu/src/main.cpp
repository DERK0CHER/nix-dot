// SHyprCtlCommand / eHyprCtlOutputFormat come from SharedDefs.hpp, which
// PluginAPI.hpp already pulls in. HyprCtl.hpp is deliberately not included:
// it would instantiate a second copy of the g_pHyprCtl inline global in this .so.
#include <hyprland/src/plugins/PluginAPI.hpp>

#include "AppmenuProtocol.hpp"
#include "protocols/appmenu.hpp"

#include <stdexcept>
#include <string>

inline HANDLE                     PHANDLE = nullptr;
inline SP<SHyprCtlCommand>        g_pAppmenuCommand;

// Mandatory: Hyprland ejects the .so if this doesn't match.
APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static std::string trimmed(const std::string& in) {
    const auto B = in.find_first_not_of(" \t\n\r");
    if (B == std::string::npos)
        return "";
    const auto E = in.find_last_not_of(" \t\n\r");
    return in.substr(B, E - B + 1);
}

// hyprctl passes the full request line, e.g. "appmenu" or "appmenu 0x55d1...".
static std::string appmenuRequest(eHyprCtlOutputFormat /* format */, std::string request) {
    if (!NAppmenu::g_pAppmenuProtocol)
        return "[]";

    // Strip the command name (and any surviving "j/" / "r/" format prefix) so
    // that what's left is the optional window address argument.
    std::string args = trimmed(request);
    const auto  POS  = args.find("appmenu");
    if (POS != std::string::npos)
        args = trimmed(args.substr(POS + std::string("appmenu").length()));

    if (args.empty())
        return NAppmenu::g_pAppmenuProtocol->dumpJSON();

    return NAppmenu::g_pAppmenuProtocol->dumpJSONFor(args);
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const std::string HASH = __hyprland_api_get_hash();

    if (HASH != __hyprland_api_get_client_hash()) {
        HyprlandAPI::addNotification(PHANDLE, "[hypr-appmenu] Failure in initialization: version mismatch (headers vs. running Hyprland)", CHyprColor{1.0, 0.2, 0.2, 1.0},
                                     5000);
        throw std::runtime_error("[hypr-appmenu] Version mismatch");
    }

    NAppmenu::g_pAppmenuProtocol = makeUnique<NAppmenu::CAppmenuProtocol>(&org_kde_kwin_appmenu_manager_interface, 1, "Appmenu");

    g_pAppmenuCommand = HyprlandAPI::registerHyprCtlCommand(PHANDLE,
                                                            SHyprCtlCommand{
                                                                .name  = "appmenu",
                                                                .exact = false, // so that "appmenu <address>" also routes here
                                                                .fn    = appmenuRequest,
                                                            });

    if (!g_pAppmenuCommand)
        HyprlandAPI::addNotification(PHANDLE, "[hypr-appmenu] could not register the 'appmenu' hyprctl command", CHyprColor{1.0, 0.6, 0.0, 1.0}, 5000);

    return {"hypr-appmenu", "org_kde_kwin_appmenu support (global menu / dbusmenu address registry)", "phase-a1", "0.1"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    if (g_pAppmenuCommand) {
        HyprlandAPI::unregisterHyprCtlCommand(PHANDLE, g_pAppmenuCommand);
        g_pAppmenuCommand.reset();
    }

    // Tears down the wl_global and every remaining record.
    NAppmenu::g_pAppmenuProtocol.reset();
}
