// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import {Collapse, Modal} from "bootstrap.native"

require("rails-ujs").start()

var Turbolinks = require("turbolinks")
Turbolinks.start()

import LiveSocket from "phoenix_live_view"
let liveSocket = new LiveSocket("/live")

document.addEventListener("turbolinks:load", function() {
  liveSocket.connect()

  // Activate collapses
  document.querySelectorAll('[data-toggle="collapse"]').forEach(element => {
    new Collapse(element)
  })
})

window.triggerModal = (html, options = {}) => {
  const container = document.querySelector("#modal-container")
  container.innerHTML = html

  const element = document.querySelector("#modal-container div")
  const modalInstance = new Modal(element, options)
  modalInstance.show()
}

window.triggerLiveSocket = () => liveSocket.connect()

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
