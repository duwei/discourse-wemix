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
        //     signature: "0x3dd68553f3b8deeb4a10906dc7625ee70fe42f185512c23ecfceffd48ecca6da13f49f6f0f9c0e6faa331977fac21c3005489fff15ad7eef46cbcea982b732dd00",
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
    if (wemixSdk.getToken() === null) {
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
