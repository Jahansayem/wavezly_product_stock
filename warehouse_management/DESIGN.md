---
version: "alpha"
name: "Halkhata Warehouse Management"
description: "A mobile-first Bengali inventory and business ledger design system with warm Halkhata branding, royal-blue operational actions, clean card-based data surfaces, and practical warehouse workflows."
colors:
  brand:
    amber:
      value: "#FFC107"
      type: "color"
      description: "Primary Halkhata brand fill for app bars, splash surfaces, and major brand moments."
    amberGradientStart:
      value: "#FBBF24"
      type: "color"
      description: "Start color for horizontal brand headers and offer surfaces."
    amberGradientEnd:
      value: "#F59E0B"
      type: "color"
      description: "End color for horizontal brand headers and offer surfaces."
    yellowAccent:
      value: "#FACC15"
      type: "color"
      description: "Bright yellow accent for highlights, selected tabs, small bars, and brand emphasis."
    yellowHover:
      value: "#E6B32F"
      type: "color"
      description: "Pressed or hover state for yellow primary controls."
  action:
    primary:
      value: "#2A5FD1"
      type: "color"
      description: "Current operational primary action color for inventory, purchase, and workflow controls."
    primaryStrong:
      value: "#2563EB"
      type: "color"
      description: "Stronger blue CTA color for buttons and important action states."
    primarySoft:
      value: "#E8EFFD"
      type: "color"
      description: "Soft blue tint used behind selected icons, inputs, and focused states."
    navigationBlue:
      value: "#3B82F6"
      type: "color"
      description: "Navigation and secondary blue for tab or bottom-bar accents."
    legacyTeal:
      value: "#26A69A"
      type: "color"
      description: "Legacy support accent still used on older operational surfaces and scanning affordances."
    legacyTealSoft:
      value: "#F0FDFA"
      type: "color"
      description: "Soft teal background for legacy highlighted cards and badges."
  surface:
    canvas:
      value: "#F3F4F6"
      type: "color"
      description: "Default app background for dashboards, ledgers, and list screens."
    canvasAlt:
      value: "#F8F9FA"
      type: "color"
      description: "Warm light-gray background for support, profile, and auth-adjacent screens."
    surface:
      value: "#FFFFFF"
      type: "color"
      description: "Card, sheet, modal, and input fill."
    surfaceMuted:
      value: "#F9FAFB"
      type: "color"
      description: "Subtle nested surface for grouped rows, input backgrounds, and quiet panels."
    surfaceCool:
      value: "#F8FAFC"
      type: "color"
      description: "Cool light surface used by transaction-heavy sales flows."
    border:
      value: "#E5E7EB"
      type: "color"
      description: "Default border and divider color."
    borderStrong:
      value: "#D1D5DB"
      type: "color"
      description: "Stronger input, chip, and segmented-control border."
  text:
    primary:
      value: "#111827"
      type: "color"
      description: "Main titles, app-bar text, key numbers, and high-emphasis labels."
    secondary:
      value: "#1F2937"
      type: "color"
      description: "Prominent body text and card headings."
    tertiary:
      value: "#374151"
      type: "color"
      description: "Default supporting labels and inactive-but-readable UI text."
    muted:
      value: "#6B7280"
      type: "color"
      description: "Metadata, placeholders, subtitles, helper text, and secondary values."
    quiet:
      value: "#9CA3AF"
      type: "color"
      description: "Disabled controls, empty states, and low-emphasis iconography."
    inverse:
      value: "#FFFFFF"
      type: "color"
      description: "Text over strong blue, green, black, or danger surfaces."
  semantic:
    success:
      value: "#16A34A"
      type: "color"
      description: "Success indicators, live status, and completed actions."
    positive:
      value: "#059669"
      type: "color"
      description: "Positive financial direction and money-entering-business states."
    positiveSoft:
      value: "#D1FAE5"
      type: "color"
      description: "Soft positive background for receive and success badges."
    danger:
      value: "#EF4444"
      type: "color"
      description: "Errors, destructive feedback, and urgent validation."
    destructive:
      value: "#DC2626"
      type: "color"
      description: "High-emphasis destructive actions and give-money states."
    destructiveSoft:
      value: "#FEE2E2"
      type: "color"
      description: "Soft destructive background for warnings, give states, and risk badges."
    warning:
      value: "#F59E0B"
      type: "color"
      description: "Expiry, attention, and warm caution states."
    warningSoft:
      value: "#FEF3C7"
      type: "color"
      description: "Soft warning background for info banners and near-expiry cards."
    receive:
      value: "#E11D48"
      type: "color"
      description: "Receive/give ledger contrast color where red denotes money leaving or owed."
typography:
  fonts:
    primary:
      value: "Anek Bangla"
      type: "fontFamily"
      description: "Primary Bengali UI font for dashboards, forms, lists, buttons, and transaction screens."
    bengaliSupport:
      value: "Hind Siliguri"
      type: "fontFamily"
      description: "Support font for Bengali-heavy profile, help, onboarding, and education surfaces."
    product:
      value: "Nunito"
      type: "fontFamily"
      description: "Rounded legacy font used in older warehouse cards and navigation labels."
    numeric:
      value: "Manrope"
      type: "fontFamily"
      description: "Dense numeric fallback for keypad, totals, and amount-heavy layouts."
  sizes:
    caption:
      value: "10px"
      type: "dimension"
    small:
      value: "12px"
      type: "dimension"
    label:
      value: "14px"
      type: "dimension"
    body:
      value: "16px"
      type: "dimension"
    title:
      value: "20px"
      type: "dimension"
    display:
      value: "26px"
      type: "dimension"
    amount:
      value: "32px"
      type: "dimension"
  weights:
    regular:
      value: "400"
      type: "fontWeight"
    medium:
      value: "500"
      type: "fontWeight"
    semibold:
      value: "600"
      type: "fontWeight"
    bold:
      value: "700"
      type: "fontWeight"
    extraBold:
      value: "800"
      type: "fontWeight"
  lineHeights:
    tight:
      value: "1.2"
      type: "number"
    normal:
      value: "1.3"
      type: "number"
    comfortable:
      value: "1.5"
      type: "number"
  styles:
    screenTitle:
      fontFamily:
        value: "Anek Bangla"
        type: "fontFamily"
      fontSize:
        value: "20px"
        type: "dimension"
      fontWeight:
        value: "700"
        type: "fontWeight"
      lineHeight:
        value: "1.3"
        type: "number"
    authDisplay:
      fontFamily:
        value: "Anek Bangla"
        type: "fontFamily"
      fontSize:
        value: "26px"
        type: "dimension"
      fontWeight:
        value: "700"
        type: "fontWeight"
      lineHeight:
        value: "1.3"
        type: "number"
    body:
      fontFamily:
        value: "Anek Bangla"
        type: "fontFamily"
      fontSize:
        value: "16px"
        type: "dimension"
      fontWeight:
        value: "400"
        type: "fontWeight"
      lineHeight:
        value: "1.5"
        type: "number"
    label:
      fontFamily:
        value: "Anek Bangla"
        type: "fontFamily"
      fontSize:
        value: "14px"
        type: "dimension"
      fontWeight:
        value: "500"
        type: "fontWeight"
      lineHeight:
        value: "1.3"
        type: "number"
    button:
      fontFamily:
        value: "Anek Bangla"
        type: "fontFamily"
      fontSize:
        value: "16px"
        type: "dimension"
      fontWeight:
        value: "600"
        type: "fontWeight"
      lineHeight:
        value: "1.3"
        type: "number"
spacing:
  xs:
    value: "4px"
    type: "dimension"
  sm:
    value: "6px"
    type: "dimension"
  md:
    value: "8px"
    type: "dimension"
  lg:
    value: "12px"
    type: "dimension"
  xl:
    value: "16px"
    type: "dimension"
  "2xl":
    value: "24px"
    type: "dimension"
  "3xl":
    value: "32px"
    type: "dimension"
  inputVertical:
    value: "14px"
    type: "dimension"
  appBarHeight:
    value: "72px"
    type: "dimension"
  bottomNavHeight:
    value: "93px"
    type: "dimension"
  maxAuthWidth:
    value: "400px"
    type: "dimension"
radii:
  xs:
    value: "2px"
    type: "dimension"
  sm:
    value: "4px"
    type: "dimension"
  md:
    value: "8px"
    type: "dimension"
  lg:
    value: "12px"
    type: "dimension"
  xl:
    value: "16px"
    type: "dimension"
  "2xl":
    value: "18px"
    type: "dimension"
  "3xl":
    value: "24px"
    type: "dimension"
  "4xl":
    value: "28px"
    type: "dimension"
  full:
    value: "9999px"
    type: "dimension"
shadows:
  soft:
    value:
      - x: "0px"
        y: "4px"
        blur: "6px"
        spread: "-1px"
        color: "rgba(0, 0, 0, 0.05)"
      - x: "0px"
        y: "2px"
        blur: "4px"
        spread: "-1px"
        color: "rgba(0, 0, 0, 0.03)"
    type: "shadow"
  card:
    value:
      x: "0px"
      y: "4px"
      blur: "8px"
      spread: "0px"
      color: "rgba(0, 0, 0, 0.08)"
    type: "shadow"
  premium:
    value:
      x: "0px"
      y: "4px"
      blur: "20px"
      spread: "0px"
      color: "rgba(0, 0, 0, 0.05)"
    type: "shadow"
  bottomBar:
    value:
      x: "0px"
      y: "-4px"
      blur: "8px"
      spread: "0px"
      color: "rgba(0, 0, 0, 0.08)"
    type: "shadow"
  floatingAction:
    value:
      x: "0px"
      y: "8px"
      blur: "18px"
      spread: "0px"
      color: "rgba(42, 95, 209, 0.28)"
    type: "shadow"
elevation:
  flat:
    value: "0"
    type: "number"
  low:
    value: "1"
    type: "number"
  appBar:
    value: "4"
    type: "number"
  floating:
    value: "8"
    type: "number"
motion:
  durations:
    fast:
      value: "180ms"
      type: "duration"
    normal:
      value: "300ms"
      type: "duration"
    expressive:
      value: "600ms"
      type: "duration"
  easing:
    standard:
      value: "ease-in-out"
      type: "cubicBezier"
    exit:
      value: "ease-out"
      type: "cubicBezier"
    emphasis:
      value: "elastic-out"
      type: "cubicBezier"
  interactions:
    tapScale:
      value: "0.98"
      type: "number"
    badgePulseScale:
      value: "1.3"
      type: "number"
components:
  appBarBrand:
    background:
      value: "linear-gradient(90deg, #FBBF24 0%, #F59E0B 100%)"
      type: "gradient"
    height:
      value: "72px"
      type: "dimension"
    foreground:
      value: "#111827"
      type: "color"
    elevation:
      value: "4"
      type: "number"
  buttonPrimary:
    background:
      value: "#2A5FD1"
      type: "color"
    foreground:
      value: "#FFFFFF"
      type: "color"
    radius:
      value: "12px"
      type: "dimension"
    paddingY:
      value: "14px"
      type: "dimension"
  buttonBrand:
    background:
      value: "#FFC107"
      type: "color"
    foreground:
      value: "#111827"
      type: "color"
    radius:
      value: "12px"
      type: "dimension"
    paddingY:
      value: "14px"
      type: "dimension"
  buttonDisabled:
    background:
      value: "#E0E0E0"
      type: "color"
    foreground:
      value: "#6B7280"
      type: "color"
  cardStandard:
    background:
      value: "#FFFFFF"
      type: "color"
    border:
      value: "#E5E7EB"
      type: "color"
    radius:
      value: "12px"
      type: "dimension"
    shadow:
      value:
        x: "0px"
        y: "4px"
        blur: "8px"
        spread: "0px"
        color: "rgba(0, 0, 0, 0.05)"
      type: "shadow"
  cardProminent:
    background:
      value: "#FFFFFF"
      type: "color"
    radius:
      value: "24px"
      type: "dimension"
    shadow:
      value:
        x: "0px"
        y: "4px"
        blur: "20px"
        spread: "0px"
        color: "rgba(0, 0, 0, 0.05)"
      type: "shadow"
  inputField:
    background:
      value: "#FFFFFF"
      type: "color"
    border:
      value: "#D1D5DB"
      type: "color"
    focusBorder:
      value: "#2A5FD1"
      type: "color"
    radius:
      value: "12px"
      type: "dimension"
  filterChip:
    background:
      value: "#FFFFFF"
      type: "color"
    foreground:
      value: "#4B5563"
      type: "color"
    border:
      value: "#E5E7EB"
      type: "color"
    radius:
      value: "9999px"
      type: "dimension"
  filterChipActive:
    background:
      value: "#2A5FD1"
      type: "color"
    foreground:
      value: "#FFFFFF"
      type: "color"
    border:
      value: "#2A5FD1"
      type: "color"
  bottomNav:
    background:
      value: "#FFFFFF"
      type: "color"
    border:
      value: "#E5E7EB"
      type: "color"
    active:
      value: "#2A5FD1"
      type: "color"
    inactive:
      value: "#9CA3AF"
      type: "color"
  fabPrimary:
    background:
      value: "#2A5FD1"
      type: "color"
    foreground:
      value: "#FFFFFF"
      type: "color"
    radius:
      value: "28px"
      type: "dimension"
  statusSuccess:
    background:
      value: "#D1FAE5"
      type: "color"
    foreground:
      value: "#059669"
      type: "color"
  statusDanger:
    background:
      value: "#FEE2E2"
      type: "color"
    foreground:
      value: "#DC2626"
      type: "color"
  statusWarning:
    background:
      value: "#FEF3C7"
      type: "color"
    foreground:
      value: "#D97706"
      type: "color"
  statusInfo:
    background:
      value: "#E8EFFD"
      type: "color"
    foreground:
      value: "#2563EB"
      type: "color"
---

## Overview

Halkhata Warehouse Management is a practical, mobile-first business app for inventory, sales, customer dues, purchasing, training, and support workflows. The visual identity is confident and utilitarian: warm amber communicates Halkhata brand presence, while royal blue carries the current operational action language. The interface should feel quick to scan in a shop or warehouse setting, with dense but readable information grouped into clean white cards on pale gray backgrounds.

The design should preserve a Bengali-first reading experience. Text must remain legible at compact sizes, numbers must be easy to compare, and every action should look immediately tappable. The app is allowed to feel warm and local through yellow headers and Bengali typography, but the body of each workflow should stay restrained, data-led, and low-friction.

## Colors

Amber and yellow are brand colors. Use them for app bars, splash moments, support CTAs, tabs, small decorative bars, and brand-backed prompts. Yellow should not dominate every action in data-heavy screens; it works best as a header or confidence signal.

Royal blue is the current primary operational color. Use it for save, add, edit, selected states, floating actions, and important workflow buttons. Keep the older teal family available only as a supporting or legacy accent where needed, especially in older stock, QR, and scanning surfaces.

White is the primary surface color. Most content appears as cards, inputs, sheets, and panels over pale gray backgrounds. Gray text should create a clear hierarchy: near-black for titles and totals, mid-gray for metadata, and light gray for disabled or empty-state UI.

Semantic color must stay meaningful. Use green for success and money entering the business, red or rose for destructive states and money leaving the business, and amber/orange for expiry, caution, and time-sensitive inventory.

## Typography

Use Anek Bangla as the primary application typeface. It should carry screen titles, list labels, card text, form labels, and Bengali workflow copy. Use Hind Siliguri for support, onboarding, and profile surfaces where the tone is slightly more conversational. Keep Nunito only for older rounded UI areas, and use Manrope sparingly for large numeric displays or calculator-like amounts.

Titles are bold but not oversized. Most mobile screens should use 18-20px titles, 14-16px body and labels, and 10-12px metadata. Bengali labels should use medium or semibold weight instead of thin weights, because the app frequently presents dense cards and small tab labels.

Amounts, inventory counts, and due totals should be visually stronger than surrounding labels. Use bold weight, high-contrast text, and enough spacing around numbers to make scanning fast.

## Layout

The app is optimized for portrait mobile. Use full-width app bars, fixed bottom navigation or bottom action bars where relevant, and scrollable card stacks for workflow content. Standard screen padding is 16px, with 24px horizontal padding reserved for auth and more focused form flows.

Cards should be compact but breathable. Use 12px radius for standard inventory, purchase, ledger, and form cards. Larger support or hero cards can use 22-28px radius when the screen is intentionally softer and less data-dense. Avoid nesting cards inside cards unless a control needs an explicit framed state.

Data lists should favor consistent rows, left-aligned names, right-aligned amounts where possible, and clear badges for status. Search, filter chips, and segmented controls should stay near the top of list screens so users can quickly narrow inventory or ledger data.

## Elevation & Depth

Depth should be soft and functional. Use subtle shadows to lift cards from pale gray backgrounds, sticky headers from content, and bottom action bars from scrollable lists. Shadows should be low-opacity black, never colored except for floating action emphasis.

Use borders and light fills more often than heavy shadows in dense data areas. Prominent cards, support call blocks, and floating actions can use larger blur values, but transactional cards should stay flatter and easier to compare.

## Shapes

The default shape language is rounded but still businesslike. Use 8px for chips, keypad controls, small cards, and compact repeated items. Use 12px for inputs, primary buttons, dialogs, and standard cards. Use 16-18px for profile fields, support panels, and larger form groupings. Use fully rounded pills for filters, language toggles, badges, and tiny status chips.

Large rounded blocks are acceptable on support and profile screens, but operational inventory and ledger screens should avoid excessive softness. The app should read as a business tool first.

## Components

Brand app bars use amber or amber gradients with dark text and simple black icons. Keep app-bar actions icon-led and high contrast.

Primary operational buttons are royal blue with white text. Brand buttons are amber with near-black text. Disabled buttons use neutral gray fills and muted gray text. Button labels should be semibold and centered.

Inputs use white fills, light gray borders, 12-16px radius, and blue or yellow focus treatment depending on the surrounding screen. Placeholders should be muted gray. Search fields should include a leading search icon and enough height for comfortable tapping.

Cards use white fills, light borders, compact shadows, and clear internal spacing. Inventory cards should show image or icon blocks, product names, metadata, stock counts, and action buttons without decorative clutter.

Filter chips are pill-shaped. Active chips should invert to a strong fill with white text, while inactive chips remain white or light gray with muted text.

Bottom navigation is white with a light top border. Active items use blue or the relevant workflow accent; inactive items remain gray. Floating actions are strong blue and should appear as obvious creation shortcuts.

## Do's and Don'ts

Do use amber for brand confidence, app structure, and support moments.

Do use royal blue for current operational actions and selected workflow states.

Do keep transaction, purchase, inventory, and due screens dense, aligned, and easy to scan.

Do reserve red, green, and amber semantic colors for true status meaning.

Do keep Bengali copy readable with medium-to-bold weights and adequate line height.

Don't turn every button yellow; yellow is brand language, not the default action language for every workflow.

Don't use heavy, dramatic shadows in lists or ledgers.

Don't use decorative gradients behind body content unless they are part of a header or brand surface.

Don't make small Bengali labels too light, too condensed, or too low contrast.

Don't mix legacy teal, royal blue, and amber in the same control group unless each color has a distinct semantic role.
