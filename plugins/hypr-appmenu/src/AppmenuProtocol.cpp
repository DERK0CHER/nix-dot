#include "AppmenuProtocol.hpp"

#include <hyprland/src/protocols/core/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/helpers/MiscFunctions.hpp>

#include <algorithm>
#include <format>

using namespace NAppmenu;

// ---------------------------------------------------------------------------
// CAppmenuEntry
// ---------------------------------------------------------------------------

CAppmenuEntry::CAppmenuEntry(SP<COrgKdeKwinAppmenu> resource, SP<CWLSurfaceResource> surface) : m_resource(resource), m_surface(surface) {
    ;
}

bool CAppmenuEntry::good() const {
    return m_resource && m_resource->resource();
}

bool CAppmenuEntry::dead() const {
    return !m_surface || m_surface.expired();
}

const std::string& CAppmenuEntry::service() const {
    return m_service;
}

const std::string& CAppmenuEntry::objectPath() const {
    return m_objectPath;
}

PHLWINDOW CAppmenuEntry::window() const {
    const auto SURF = m_surface.lock();
    if (!SURF)
        return nullptr;

    // Walk the compositor's window list and match on the toplevel's root surface.
    // Resolved on every call: a client may create the appmenu object before its
    // window exists, and the window may be recreated over the plugin's lifetime.
    for (const auto& w : Desktop::windowState()->windows()) {
        if (!w)
            continue;

        if (w->resource() == SURF)
            return w;
    }

    return nullptr;
}

std::string CAppmenuEntry::windowAddress() const {
    const auto W = window();
    if (!W)
        return "";

    return std::format("0x{:x}", reinterpret_cast<uintptr_t>(W.get()));
}

// ---------------------------------------------------------------------------
// CAppmenuProtocol
// ---------------------------------------------------------------------------

CAppmenuProtocol::CAppmenuProtocol(const wl_interface* iface, const int& ver, const std::string& name) : IWaylandProtocol(iface, ver, name) {
    ;
}

void CAppmenuProtocol::bindManager(wl_client* client, void* data, uint32_t ver, uint32_t id) {
    const auto RESOURCE = m_managers.emplace_back(makeUnique<COrgKdeKwinAppmenuManager>(client, ver, id)).get();

    if (!RESOURCE->resource()) {
        LOGM(Log::ERR, "Couldn't create an appmenu manager");
        wl_client_post_no_memory(client);
        m_managers.pop_back();
        return;
    }

    RESOURCE->setOnDestroy([this](COrgKdeKwinAppmenuManager* mgr) { this->onManagerResourceDestroy(mgr); });
    RESOURCE->setCreate([this](COrgKdeKwinAppmenuManager* mgr, uint32_t id, wl_resource* surface) { this->onCreate(mgr, id, surface); });
}

void CAppmenuProtocol::onManagerResourceDestroy(COrgKdeKwinAppmenuManager* mgr) {
    std::erase_if(m_managers, [mgr](const auto& other) { return other.get() == mgr; });
}

void CAppmenuProtocol::pruneDead() {
    // Only ever called from a context that is NOT inside one of the pruned
    // entries' own callbacks (a new bind/create, or an hyprctl query).
    std::erase_if(m_entries, [](const auto& e) { return !e || e->dead(); });
}

void CAppmenuProtocol::onCreate(COrgKdeKwinAppmenuManager* mgr, uint32_t id, wl_resource* surface) {
    pruneDead();

    const auto CLIENT = mgr->client();
    const auto SURF   = CWLSurfaceResource::fromResource(surface);

    if (!SURF) {
        // The protocol declares no error codes, so all we can do is refuse.
        LOGM(Log::ERR, "appmenu: create with an invalid wl_surface");
        wl_client_post_implementation_error(CLIENT, "org_kde_kwin_appmenu_manager.create: invalid wl_surface");
        return;
    }

    const auto ENTRY = m_entries.emplace_back(makeUnique<CAppmenuEntry>(makeShared<COrgKdeKwinAppmenu>(CLIENT, mgr->version(), id), SURF)).get();

    if (!ENTRY->good()) {
        LOGM(Log::ERR, "Couldn't create an appmenu entry");
        wl_client_post_no_memory(CLIENT);
        m_entries.pop_back();
        return;
    }

    ENTRY->m_resource->setOnDestroy([this](COrgKdeKwinAppmenu* r) { this->destroyEntry(r); });
    ENTRY->m_resource->setRelease([this](COrgKdeKwinAppmenu* r) { this->destroyEntry(r); });
    ENTRY->m_resource->setSetAddress([ENTRY](COrgKdeKwinAppmenu*, const char* service, const char* path) {
        ENTRY->m_service    = service ? service : "";
        ENTRY->m_objectPath = path ? path : "";
        LOGM(Log::TRACE, "appmenu: set_address {} {}", ENTRY->m_service, ENTRY->m_objectPath);
    });

    // Drop our reference to the surface the moment it dies. The record itself is
    // reaped by pruneDead() at the next safe point; erasing it from inside this
    // listener would free the listener while it is running.
    ENTRY->m_listeners.surfaceDestroy = SURF->m_events.destroy.listen([ENTRY]() { ENTRY->m_surface.reset(); });

    LOGM(Log::DEBUG, "appmenu: new entry for surface {:x}", reinterpret_cast<uintptr_t>(SURF.get()));
}

void CAppmenuProtocol::destroyEntry(COrgKdeKwinAppmenu* resource) {
    std::erase_if(m_entries, [resource](const auto& e) { return e && e->m_resource.get() == resource; });
}

// ---------------------------------------------------------------------------
// query interface
// ---------------------------------------------------------------------------

static std::string entryJSON(const std::string& address, const std::string& service, const std::string& path) {
    return std::format(R"#({{"address": "{}", "service": "{}", "path": "{}"}})#", escapeJSONStrings(address), escapeJSONStrings(service), escapeJSONStrings(path));
}

std::string CAppmenuProtocol::dumpJSON() {
    pruneDead();

    std::string result = "[";
    bool        first  = true;

    for (const auto& e : m_entries) {
        if (!e || e->service().empty())
            continue;

        const auto ADDR = e->windowAddress();
        if (ADDR.empty())
            continue;

        if (!first)
            result += ", ";
        first = false;

        result += entryJSON(ADDR, e->service(), e->objectPath());
    }

    return result + "]";
}

std::string CAppmenuProtocol::dumpJSONFor(const std::string& address) {
    pruneDead();

    for (const auto& e : m_entries) {
        if (!e || e->service().empty())
            continue;

        const auto ADDR = e->windowAddress();
        if (ADDR.empty() || ADDR != address)
            continue;

        return entryJSON(ADDR, e->service(), e->objectPath());
    }

    return "{}";
}
