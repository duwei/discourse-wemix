import { createWidget } from "discourse/widgets/widget";
// import DiscourseURL, { userPath } from "discourse/lib/url";
// import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
// import getURL from "discourse-common/lib/get-url";
import { h } from "virtual-dom";
// import { later } from "@ember/runloop";

// const flatten = (array) => [].concat.apply([], array);
const WALLET_STATUS = "wallet-status";

createWidget("wallet-menu-detail", {
  buildKey: () => "wallet-menu-tokens",
  tagName: "div.wrap",
  defaultState() {
    return { balances: [], loaded: false, loading:false };
  },
  updateBalances(state) {
    if (state.loading) {
      return;
    }
    state.loading = true;

    let wemix = window.wemix();
    return wemix.balanceAll().then(c=>{
      state.balances = c.data.balances;
      state.loaded = true;
      this.scheduleRerender();
    }).catch(error=>{
      console.log(error);
    }).finally(() => {
      state.loading = false;
    });
  },
  html(atts, state) {
    console.log("menu-tokens");
    console.log(state);
    if (!state.loaded) {
      this.updateBalances(state);
    }
    let contents = [];
    let inner = [];
    let keys = Object.keys(this.state.balances);
    for(let i=0;i<keys.length;i++){
      contents.push(h("div.hc-column",keys[i]+":"+this.state.balances[keys[i]]));
    }
    let row1 = h("div.row-cont", contents);
    let h1 = h('div.top-spot',h('h1','Tokens'));
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
  tagName: 'div.wallet-menu',

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
    let wallet_status = sessionStorage.getItem(WALLET_STATUS) || false;
    return { loaded: false, connected: wallet_status };
  },

  retrieveWalletStatus(state) {
    const { currentUser } = this;

    if (state.loading || !currentUser) {
      return;
    }

    state.loading = true;

    return ajax("/wemix/test")
      .then((data) => {
        console.log(data);
        state.connected = true;
      })
      .finally(() => {
        state.loaded = true;
        state.loading = false;
        this.scheduleRerender();
      });
  },

  html(atts, state) {
    let wemix = window.wemix();
    console.log("menu");
    console.log(state);
    if (!state.connected) {
      // this.retrieveWalletStatus(state);
      wemix.openQR("auth",null,
        success=>{
          console.log(success);
          wemix.login().then(
            ok => {
              console.log(ok);
              return ajax("/wemix/connect", {
                type: "PUT",
                data: {
                  wemix_id: ok.data.userID,
                  wemix_address: ok.data.address
                }
              }).then((data) => {
                console.log(data);
          state.connected = true;
          sessionStorage.setItem(WALLET_STATUS, true);
              }).finally(() => {
                  this.scheduleRerender();
              });
            },
            ng => {
              console.log(ng);
            }
          );
          console.log(user);
        },
        fail=>{
          console.log(fail);
        });
    } else {
      return this.attach('menu-panel', {
        contents: () => this.panelContents(),
        maxWidth: this.settings.maxWidth
      });
    }
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

