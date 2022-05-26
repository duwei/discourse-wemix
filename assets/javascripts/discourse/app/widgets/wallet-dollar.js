import { createWidget } from "discourse/widgets/widget";
import { ajax } from "discourse/lib/ajax";
import { h } from "virtual-dom";
import { getOwner } from "discourse-common/lib/get-owner";
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
    console.log("getRawMessage");
    return ajax("/wemix/point/tx", {
      type: "POST",
    }).then((data) => {
      if (data.code === 0) {
        wemixSdk.signMessage(data.message, data.data);
      }
    }).finally(() => {
    });
  },

  click() {
    if (!wemixSdk.getWallet()) {
      wemixSdk.auth();
    } else {
      console.log("bbb");
      // showModal("test");
      // this.attach("wallet-banner");
      this.sendWidgetAction("getRawMessage", {});
    }
  },

  // clickOutside() {
  // }
});
