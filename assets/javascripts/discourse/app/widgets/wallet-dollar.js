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
        // return ajax("/wemix/exchange", {
        //   type: "POST",
        //   data: {
        //     signature: "0xdfd077fdc86b7324764f0d00255efe66173b54f2c7a71cfe592de48a513038de6de37caa9dcb792ca3d99f5d295e34b6c3351260abd549a74f3fedc0a25931ce1c",
        //   }
        // }).then((data) => {
        //   if (data.code === 0) {
        //     console.log(data);
        //     // wemixSdk.signMessage(data.message, data.data);
        //   }
        // }).finally(() => {
        // });
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
