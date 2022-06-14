import { createWidget } from "discourse/widgets/widget";
import { ajax } from "discourse/lib/ajax";
import { h } from "virtual-dom";
import { getOwner } from "discourse-common/lib/get-owner";
import hbs from "discourse/widgets/hbs-compiler";
import { iconNode } from "discourse/helpers/fa-icon-node";
import I18n from "I18n";
import wemixSdk from "../../../lib/wemix-sdk";

export default createWidget('wallet-dollar', {
  tagName: 'a',
  buildKey: () => 'wallet-dollar',

  defaultState() {
    return { loaded: false };
  },

  html(attrs, state) {
    // return `Click me! ${state.clicks} clicks`;
    return [iconNode('dollar-sign', { title: I18n.t("wallet.dollar")})];
  },

  getPointMessage() {
    ajax("/wemix/point/tx", {
      type: "POST",
    }).then((data) => {
      if (data.code === 0) {
        console.log(data);
        wemixSdk.signMessage(data.message, data.data);
        return ajax("/wemix/exchange", {
          type: "POST",
          data: {
            signature: "0x11489b623246e18d26505d38401a63903d19fbc694db6126637ff6d5c3b89d094cdd6ada6a985d17d0604c46cfc42f5b16136872fa49e44891a667a3eea653c801",
          }
        }).then((data) => {
          if (data.code === 0) {
            console.log(data);
            // wemixSdk.signMessage(data.message, data.data);
          }
        }).finally(() => {
        });
      }
    }).finally(() => {
    });
  },

  click() {
    return this.sendWidgetAction("getPointMessage", {});
    if (wemixSdk.getToken() == null) {
      wemixSdk.auth();
    } else {
      // showModal("test");
      // this.attach("wallet-banner");
      this.sendWidgetAction("getPointMessage", {});
    }
  },

  // clickOutside() {
  // }
});
