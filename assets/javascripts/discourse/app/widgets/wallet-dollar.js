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
        // wemixSdk.signMessage(data.message, data.data);
        return ajax("/wemix/exchange", {
          type: "POST",
          data: {
            signature: "0x0425b8292c36325fa2c023fb55c6efad2e9db7cec27ff9dc01a90851da4b85297751031fc4dc3338da80f4d2ff21d364e0eb0d33c194c0e21108cf3ec35723fe1b",
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
