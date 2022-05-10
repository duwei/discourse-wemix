import { createWidget } from "discourse/widgets/widget";
// import DiscourseURL, { userPath } from "discourse/lib/url";
// import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
// import getURL from "discourse-common/lib/get-url";
import { h } from "virtual-dom";
// import { later } from "@ember/runloop";

// const flatten = (array) => [].concat.apply([], array);

createWidget("wallet-menu-detail", {
  tagName: "div.wrap",
  html() {
    let contents = [];
    contents.push(h("div.hc-column","hello1"));
    contents.push(h("div.hc-column","hello2"));
    contents.push(h("div.hc-column","hello3"));
    let row1 = h("div.row-cont", contents);
    let h1 = h('div.top-spot',h('h1','hello4'));
    let inner = [];
    let bottoni = [];
    let row2 = h("div.row-cont", bottoni);
    inner.push(h1,row1,row2);
    return h("div.hc-banner",inner);
  },
});

createWidget("wallet-menu-qrcode", {
  tagName: "div.wrap",
  html() {
    let contents = [];
    let row1 = h("div.row-cont", contents);
    let h1 = h('div.top-spot',h('h1','QRCode'));
    let inner = [];
    let bottoni = [];
    let row2 = h("div.row-cont", bottoni);
    inner.push(h1,row1,row2);
    return h("div.hc-banner",inner);
  },
});

export default createWidget('wallet-menu', {
  buildKey: () => "wallet-menu",
  tagName: 'div.wallet-panel',

  settings: {
    maxWidth: 320
  },

  panelContents() {
    if (this.state.connected) {
      return this.attach("wallet-menu-detail");
    } else {
      return this.attach("wallet-menu-qrcode");
    }
  },

  defaultState() {
    return { loaded: false, connected: false };
  },

  retrieveWalletStatus(state) {
    const { currentUser } = this;

    if (state.loading || !currentUser) {
      return;
    }

    state.loading = true;

    return ajax("/review/count.json")
      .then(({ }) => state.connected = true)
      .finally(() => {
        state.loaded = true;
        state.loading = false;
        this.scheduleRerender();
      });
  },

  html(atts, state) {
    if (!state.loaded) {
      this.retrieveWalletStatus(state);
    }
    return this.attach('menu-panel', {
      contents: () => this.panelContents(),
      maxWidth: this.settings.maxWidth
    });
  },

  clickOutside(event) {
    if (this.site.mobileView) {
      this.clickOutsideMobile(event);
    } else {
      this.sendWidgetAction('toggleWalletMenu');
    }
  },

  clickOutsideMobile(event) {
    const centeredElement = document.elementFromPoint(event.clientX, event.clientY);
    if (
      !centeredElement.classList.contains('header-cloak') &&
      centeredElement.closest('.panel').length > 0
    ) {
      this.sendWidgetAction('toggleWalletMenu');
    } else {
      const panel = document.querySelector('.menu-panel');
      panel.classList.add('animate');
      const panelOffsetDirection = this.site.mobileView ? 'left' : 'right';
      panel.style.setProperty(panelOffsetDirection, -window.innerWidth);

      const headerCloak = document.querySelector('.header-cloak');
      headerCloak.classList.add('animate');
      headerCloak.style.setProperty('opacity', 0);

      Ember.run.later(() => this.sendWidgetAction('toggleWalletMenu'), 200);
    }
  }
});

