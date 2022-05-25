import { createWidget } from "discourse/widgets/widget";
// import DiscourseURL, { userPath } from "discourse/lib/url";
// import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
// import getURL from "discourse-common/lib/get-url";
import { h } from "virtual-dom";
// import { later } from "@ember/runloop";
import { getOwner } from "discourse-common/lib/get-owner";
import wemixSdk from "../../../lib/wemix-sdk";
// const flatten = (array) => [].concat.apply([], array);

createWidget("wallet-menu-detail", {
  buildKey: () => "wallet-menu-tokens",
  tagName: "div.wrap",
  defaultState() {
    return { balances: [], loaded: false, loading:false, refresh_point: false };
  },
  updatePoint(state) {
    if (state.refresh_point) {
      return;
    }
    state.refresh_point = true;

    return ajax("/wemix/point")
      .then((data) => {
        this.currentUser.set('point', data.point);
        this.scheduleRerender();
      })
      .finally(() => {
        state.refresh_point = false;
      });
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
      this.updatePoint(state);
    }
    const owner = getOwner(this);
    if (owner.isDestroyed || owner.isDestroying) {
      return;
    }

    const siteSettings = owner.lookup("site-settings:main");
    let contents = [];
    let inner = [];
    let keys = Object.keys(this.state.balances);
    const tokens = siteSettings.wemix_tokens.split(",").map(function(item) {
      return item.trim();
    });
    for(let i=0;i<keys.length;i++){
      if (tokens.indexOf(keys[i]) !== -1) {
        contents.push(h("div.hc-column",keys[i]+":"+this.state.balances[keys[i]]));
      }
    }
    let row1 = h("div.row-cont", contents);
    let h1 = h('div.top-spot',h('h1','Tokens'));
    let bottoni = [h("div.hc-column","point :" + this.currentUser.get('point'))];
    let row2 = h("div.row-cont", bottoni);
    inner.push(h1,row2,row1);
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
    return this.attach("wallet-menu-detail");
  },

  defaultState() {
    return { loaded: false };
  },

  testApi(state) {
    const { currentUser } = this;

    if (state.loading || !currentUser) {
      return;
    }

    state.loading = true;

    return ajax("/wemix/point")
      .then((data) => {
      console.log(data);
      })
      .finally(() => {
    });
  },

  html(atts, state) {
    if (!wemixSdk.getWallet()) {
      let onUpdate = function (data) {
        console.log(data);
        this.scheduleRerender();
      };
      wemixSdk.auth(onUpdate);
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

