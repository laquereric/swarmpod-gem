// ActionCable consumer setup for SwarmpodGem
//
// Uses ActionCable to replace raw WebSocket connections.
// Expects ActionCable to be available globally (from rails/actioncable).

(function() {
  "use strict";

  // Detect base path from the <meta name="swarmpod-mount"> tag or default to ""
  var mountEl = document.querySelector('meta[name="swarmpod-mount"]');
  var basePath = mountEl ? mountEl.getAttribute("content") : "";
  var cableUrl = basePath + "/cable";

  // Create ActionCable consumer
  window.SwarmpodCable = {
    consumer: null,
    subscription: null,

    connect: function(onReceived) {
      if (typeof ActionCable === "undefined") {
        console.error("ActionCable not loaded");
        return;
      }

      this.consumer = ActionCable.createConsumer(cableUrl);
      this.subscription = this.consumer.subscriptions.create(
        { channel: "SwarmpodGem::DashboardChannel" },
        {
          connected: function() {
            document.getElementById("connection-status").textContent = "connected";
            document.getElementById("connection-status").className = "connection-badge connected";
          },

          disconnected: function() {
            document.getElementById("connection-status").textContent = "disconnected";
            document.getElementById("connection-status").className = "connection-badge disconnected";
          },

          received: function(data) {
            if (onReceived) onReceived(data);
          }
        }
      );
    },

    disconnect: function() {
      if (this.consumer) {
        this.consumer.disconnect();
      }
    }
  };
})();
