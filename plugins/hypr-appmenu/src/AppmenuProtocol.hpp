#pragma once

// Implementation of the org_kde_kwin_appmenu Wayland protocol for Hyprland.
//
// The protocol is a two-interface affair:
//   org_kde_kwin_appmenu_manager.create(id, wl_surface) -> org_kde_kwin_appmenu
//   org_kde_kwin_appmenu.set_address(service_name, object_path)
//   org_kde_kwin_appmenu.release()  (destructor)
//
// A client uses it to announce "the com.canonical.dbusmenu export for this
// surface lives at <bus name><object path>". A global menu bar then reads
// that mapping and renders the menu of whatever window is focused.
//
// This class keeps one record per live org_kde_kwin_appmenu object and can
// resolve each record's wl_surface to a Hyprland window on demand.

#include <hyprland/src/protocols/WaylandProtocol.hpp>
#include <hyprland/src/desktop/DesktopTypes.hpp>
#include <hyprland/src/helpers/signal/Signal.hpp>

#include "protocols/appmenu.hpp"

#include <string>
#include <vector>

class CWLSurfaceResource;

namespace NAppmenu {
    class CAppmenuProtocol;

    // One live org_kde_kwin_appmenu object == one {surface, service, path} record.
    class CAppmenuEntry {
      public:
        CAppmenuEntry(SP<COrgKdeKwinAppmenu> resource, SP<CWLSurfaceResource> surface);
        ~CAppmenuEntry() = default;

        CAppmenuEntry(const CAppmenuEntry&)            = delete;
        CAppmenuEntry& operator=(const CAppmenuEntry&) = delete;

        bool               good() const;

        // true once the client's wl_surface went away; such entries are pruned
        // at the next safe point (see CAppmenuProtocol::pruneDead).
        bool               dead() const;

        const std::string& service() const;
        const std::string& objectPath() const;

        // Resolves the stored wl_surface to a Hyprland window by walking the
        // compositor's window list. Resolved lazily (and never cached) because
        // clients usually create the appmenu object before the window is mapped.
        PHLWINDOW          window() const;

        // "0x55d1..." - the same address format hyprctl clients/activewindow use.
        std::string        windowAddress() const;

      private:
        SP<COrgKdeKwinAppmenu> m_resource;
        WP<CWLSurfaceResource> m_surface;

        std::string            m_service;
        std::string            m_objectPath;

        struct {
            CHyprSignalListener surfaceDestroy;
        } m_listeners;

        friend class CAppmenuProtocol;
    };

    class CAppmenuProtocol : public IWaylandProtocol {
      public:
        CAppmenuProtocol(const wl_interface* iface, const int& ver, const std::string& name);

        virtual void bindManager(wl_client* client, void* data, uint32_t ver, uint32_t id);

        // --- userspace query interface ---------------------------------------
        // JSON array of every record that currently resolves to a window.
        std::string dumpJSON();
        // JSON object for one window address ("0x..."), or "{}" if unknown.
        std::string dumpJSONFor(const std::string& address);

      private:
        void                                       onManagerResourceDestroy(COrgKdeKwinAppmenuManager* mgr);
        void                                       onCreate(COrgKdeKwinAppmenuManager* mgr, uint32_t id, wl_resource* surface);
        void                                       destroyEntry(COrgKdeKwinAppmenu* resource);
        void                                       pruneDead();

        std::vector<UP<COrgKdeKwinAppmenuManager>> m_managers;
        std::vector<UP<CAppmenuEntry>>             m_entries;

        friend class CAppmenuEntry;
    };
};

namespace NAppmenu {
    inline UP<CAppmenuProtocol> g_pAppmenuProtocol;
};
