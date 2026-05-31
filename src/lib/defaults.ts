import { DEFAULT_LOCALE } from "./locale";
import type { Device, ProjectState, Slide } from "./types";

let _id = 0;
export const nid = () => `s_${Date.now().toString(36)}_${(_id++).toString(36)}`;

const en = (s: string) => ({ [DEFAULT_LOCALE]: s });

function makeStarterSlides(): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("PARASENDE"),
      headline: en("Toptan satış\ntek ekranda."),
      screenshot: "/screenshots/apple/iphone/tr/01.png",
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("ÜRÜNLER"),
      headline: en("Ürünlerini\nhızlı bul."),
      screenshot: "/screenshots/apple/iphone/tr/01.png",
    },
    {
      id: nid(),
      layout: "two-devices",
      label: en("SİPARİŞ"),
      headline: en("Sepeti hazırla,\nsatışı tamamla."),
      screenshot: "/screenshots/apple/iphone/tr/02.png",
      screenshotSecondary: "/screenshots/apple/iphone/tr/03.png",
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("FATURA"),
      headline: en("Faturayı anında\noluştur."),
      screenshot: "/screenshots/apple/iphone/tr/03.png",
      inverted: true,
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("RAPORLAR"),
      headline: en("Kazancını\nnet gör."),
      screenshot: "/screenshots/apple/iphone/tr/04.png",
    },
  ];
}

function androidStarterSlides(): Slide[] {
  return makeStarterSlides().map((slide) => ({
    ...slide,
    screenshot: slide.screenshot.replace("/screenshots/apple/iphone/", "/screenshots/android/phone/"),
    screenshotSecondary: slide.screenshotSecondary?.replace(
      "/screenshots/apple/iphone/",
      "/screenshots/android/phone/",
    ),
  }));
}

function ipadStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET YOUR APP"),
      headline: en("Made for\nthe big screen."),
      screenshot: "",
    },
    {
      id: nid(),
      layout: "device-bottom",
      label: en("FEATURE 01"),
      headline: en("Built for\nfocus."),
      screenshot: "",
    },
    {
      id: nid(),
      layout: "device-top",
      label: en("FEATURE 02"),
      headline: en("Always within reach."),
      screenshot: "",
      inverted: true,
    },
  ];
}

function tabletStarter(kind: "7" | "10"): Slide[] {
  return [
    {
      id: nid(),
      layout: "hero",
      label: en("MEET YOUR APP"),
      headline: en(kind === "7" ? "Pocket-sized\npower." : "Made for\nthe big screen."),
      screenshot: "",
    },
    {
      id: nid(),
      layout: "split-landscape",
      label: en("FEATURE 01"),
      headline: en("Wide canvas,\nbigger ideas."),
      screenshot: "",
    },
  ];
}

function fgStarter(): Slide[] {
  return [
    {
      id: nid(),
      layout: "feature-graphic",
      label: {},
      headline: en("Your tagline goes here."),
      screenshot: "",
    },
  ];
}

export const DEFAULT_PROJECT: ProjectState = {
  appName: "ParaSende",
  themeId: "warm-editorial",
  locales: [DEFAULT_LOCALE],
  locale: DEFAULT_LOCALE,
  device: "iphone",
  orientation: "portrait",
  appIcon: "/app-icon.png",
  slidesByDevice: {
    iphone: makeStarterSlides(),
    android: androidStarterSlides(),
    ipad: ipadStarter(),
    "android-7": tabletStarter("7"),
    "android-10": tabletStarter("10"),
    "feature-graphic": fgStarter(),
  },
};

export function newSlide(layout: Slide["layout"] = "device-bottom"): Slide {
  return {
    id: nid(),
    layout,
    label: en("NEW"),
    headline: en("Edit this\nheadline."),
    screenshot: "",
  };
}

export function detectPlatform(device: Device): "ios" | "android" {
  return device === "iphone" || device === "ipad" ? "ios" : "android";
}
