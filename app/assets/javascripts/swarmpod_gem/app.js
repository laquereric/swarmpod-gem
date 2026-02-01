// SwarmPod Dashboard - ActionCable version
// Ported from swarmpod/public/app.js

(function() {
  "use strict";

  var currentState = { tabs: {}, activeTab: "", tabAgents: {}, tabEvents: {}, messages: [] };

  // Detect base path from the <meta name="swarmpod-mount"> tag
  var mountEl = document.querySelector('meta[name="swarmpod-mount"]');
  var basePath = mountEl ? mountEl.getAttribute("content") : "";

  // --- ActionCable connection ---

  function connect() {
    if (window.SwarmpodCable) {
      window.SwarmpodCable.connect(function(data) {
        currentState = data;
        render();
      });
    }
  }

  // --- Initial load via HTTP ---

  function loadInitialState() {
    fetch(basePath + "/api/state")
      .then(function(res) { return res.json(); })
      .then(function(data) {
        currentState = data;
        render();
      })
      .catch(function() {});
  }

  // --- Rendering ---

  function render() {
    renderTabs();
    renderTabContent();
  }

  function renderTabs() {
    var tabBar = document.getElementById("tab-bar");
    var tabIds = Object.keys(currentState.tabs || {});

    tabBar.innerHTML = tabIds.map(function(id) {
      var tab = currentState.tabs[id];
      var isActive = id === currentState.activeTab;
      var isLoading = tab.status === "loading";
      var isDisabled = isLoading;
      var statusIcon = tab.status === "loading" ? '<span class="clone-spinner"></span>'
        : tab.status === "error" ? '<span class="tab-error-dot"></span>'
        : tab.status === "pending" ? '<span class="tab-pending-dot"></span>'
        : "";

      return '<button class="tab-btn' + (isActive ? " active" : "") + '"'
        + ' data-tab="' + escapeHtml(id) + '"'
        + (isDisabled ? " disabled" : "") + '>' + statusIcon + escapeHtml(id)
        + '<span class="tab-gem-count">' + (tab.gemCount || 0) + '</span></button>';
    }).join("");

    tabBar.querySelectorAll(".tab-btn").forEach(function(btn) {
      btn.addEventListener("click", function() {
        activateTab(btn.dataset.tab);
      });
    });
  }

  function activateTab(tabId) {
    currentState.activeTab = tabId;
    render();

    fetch(basePath + "/api/tab/" + encodeURIComponent(tabId), { method: "POST" })
      .catch(function(err) { console.error("Tab activation failed:", err); });
  }

  function renderTabContent() {
    var content = document.getElementById("tab-content");
    var tabId = currentState.activeTab;
    var tab = currentState.tabs ? currentState.tabs[tabId] : null;

    if (!tab) {
      content.innerHTML = '<div class="empty-state">No tabs available</div>';
      return;
    }

    if (tab.status === "loading") {
      content.innerHTML = '<div class="tab-loading-state">'
        + '<div class="clone-spinner large"></div>'
        + '<p>Cloning gems for <strong>' + escapeHtml(tabId) + '</strong>...</p>'
        + '</div>';
      return;
    }

    if (tab.status === "error") {
      content.innerHTML = '<div class="tab-error-state">'
        + '<p>Failed to load gems for <strong>' + escapeHtml(tabId) + '</strong></p>'
        + '<button class="retry-btn" onclick="window.swarmpodActivateTab(\'' + escapeHtml(tabId) + '\')">Retry</button>'
        + '</div>';
      return;
    }

    if (tab.status === "pending") {
      content.innerHTML = '<div class="tab-pending-state">'
        + '<p>Click to activate <strong>' + escapeHtml(tabId) + '</strong> tab</p>'
        + '<p class="text-muted">' + (tab.gemCount || 0) + ' gem' + ((tab.gemCount || 0) !== 1 ? 's' : '') + ' will be cloned on activation</p>'
        + '</div>';
      return;
    }

    // Ready state
    content.innerHTML = '<form id="message-form" class="message-form">'
      + '<input type="text" id="message-input" placeholder="Describe a task for the swarm..." autocomplete="off" required>'
      + '<button type="submit">Send</button>'
      + '</form>'
      + '<section id="agent-grid" class="agent-grid"></section>'
      + '<section class="event-log-section">'
      + '<h2>Event Log</h2>'
      + '<div id="event-log" class="event-log"></div>'
      + '</section>';

    initMessageForm();
    renderAgentCards();
    renderEventLog();
  }

  function renderAgentCards() {
    var grid = document.getElementById("agent-grid");
    if (!grid) return;

    var tabId = currentState.activeTab;
    var agents = currentState.tabAgents ? (currentState.tabAgents[tabId] || {}) : {};
    var agentIds = Object.keys(agents);

    if (agentIds.length === 0) {
      grid.innerHTML = '<div class="empty-state">Waiting for agents...</div>';
      return;
    }

    grid.innerHTML = agentIds.map(function(id) {
      var agent = agents[id];
      var color = agent.color || "#888";
      return agentCardHTML(agent, color);
    }).join("");
  }

  function agentCardHTML(agent, color) {
    var toolCounts = agent.toolCounts || {};
    var toolChips = Object.keys(toolCounts).sort(function(a, b) {
      return toolCounts[b] - toolCounts[a];
    }).map(function(name) {
      return '<span class="tool-chip">' + escapeHtml(name) + '<span class="count">' + toolCounts[name] + '</span></span>';
    }).join("");

    var metaHTML = "";
    if (agent.status === "completed" || agent.status === "error") {
      metaHTML = '<div class="agent-meta">';
      if (agent.duration) {
        metaHTML += '<span><span class="label">Duration:</span><span class="value">' + escapeHtml(agent.duration) + '</span></span>';
      }
      if (agent.cost != null) {
        metaHTML += '<span><span class="label">Cost:</span><span class="value">$' + Number(agent.cost).toFixed(4) + '</span></span>';
      }
      metaHTML += '</div>';
    }

    return '<div class="agent-card" style="--agent-color: ' + color + '">'
      + '<div class="agent-header">'
      + '<span class="agent-name">' + escapeHtml(agent.id) + '</span>'
      + '<span class="status-badge ' + agent.status + '">'
      + '<span class="pulse"></span>'
      + agent.status
      + '</span>'
      + '</div>'
      + '<div class="agent-tools">'
      + '<h4>Tools</h4>'
      + '<div class="tool-list">'
      + (toolChips || '<span class="tool-chip">none yet</span>')
      + '</div>'
      + '</div>'
      + '<div class="agent-activity">'
      + (agent.lastActivity ? escapeHtml(agent.lastActivity) : "Waiting...")
      + '</div>'
      + metaHTML
      + '</div>';
  }

  function renderEventLog() {
    var log = document.getElementById("event-log");
    if (!log) return;

    var tabId = currentState.activeTab;
    var events = currentState.tabEvents ? (currentState.tabEvents[tabId] || []) : [];

    if (events.length === 0) {
      log.innerHTML = '<div class="empty-state">No events yet</div>';
      return;
    }

    var wasAtBottom = log.scrollTop + log.clientHeight >= log.scrollHeight - 30;

    var agents = currentState.tabAgents ? (currentState.tabAgents[tabId] || {}) : {};
    var colorMap = { user: "#eab308", system: "#71717a" };
    for (var id in agents) {
      if (agents.hasOwnProperty(id)) {
        colorMap[id] = agents[id].color || "#888";
      }
    }

    log.innerHTML = events.map(function(evt) {
      var time = new Date(evt.timestamp).toLocaleTimeString();
      var color = colorMap[evt.agentId] || "#888";
      return '<div class="event-entry">'
        + '<span class="event-time">' + time + '</span>'
        + '<span class="event-agent" style="color: ' + color + '">' + escapeHtml(evt.agentId) + '</span>'
        + '<span class="event-type">' + escapeHtml(evt.type) + '</span>'
        + '<span class="event-detail">' + escapeHtml(evt.detail || "") + '</span>'
        + '</div>';
    }).join("");

    if (wasAtBottom) {
      log.scrollTop = log.scrollHeight;
    }
  }

  function escapeHtml(str) {
    if (!str) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  // --- Message Form ---

  function initMessageForm() {
    var form = document.getElementById("message-form");
    var input = document.getElementById("message-input");
    if (!form || !input) return;

    form.addEventListener("submit", function(e) {
      e.preventDefault();
      var text = input.value.trim();
      if (!text) return;

      input.value = "";

      var tabId = currentState.activeTab;

      // Show user message in event log immediately
      var userEvt = {
        agentId: "user",
        type: "message",
        detail: text,
        timestamp: Date.now()
      };
      if (!currentState.tabEvents[tabId]) currentState.tabEvents[tabId] = [];
      currentState.tabEvents[tabId].push(userEvt);
      renderEventLog();

      fetch(basePath + "/api/message", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: text })
      }).catch(function(err) {
        console.error("Failed to send message:", err);
      });
    });
  }

  // Expose activateTab for retry button onclick
  window.swarmpodActivateTab = activateTab;

  // --- Init ---
  loadInitialState();
  connect();
})();
