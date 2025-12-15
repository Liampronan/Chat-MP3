# Chat-MP3: Embedded Audio Player

A music player component built with SwiftUI.

## 📺 Video Walkthrough

[![Watch the demo](https://img.youtube.com/vi/mTLKXhkqEZw/0.jpg)](https://www.youtube.com/watch?v=mTLKXhkqEZw)

**Video Timeline:**

- 00:00 - Intro/Overview
- 00:31 - Main Features Walkthrough
- 04:19 - Scrolling Title WIP
- 06:40 - Accessibility
- 07:33 - Progress, Error view
- 08:54 - Design-Code Tie-Ins for Scaling UX Beyond Prototyp

---

## How I'd use an additional hour on this prototype

- Complete the implementation of the scrolling title view (for longer track/artist names).
- Implement a widget layout to enable multi-context usage of the MusicPlayerView; tweak UI for this new widget context.
- Add light mode: right now, it's solely styled for Dark mode.
  - The colors are configured to support user switching system-level light/dark mode changing (via iOS Color Set assets) but I haven't added colors for light mode. 
- Add loading progress view for album art; consider something like a gradient color based on the primary colors of the art [example](https://github.com/hulk-2019/camarts-placeholder).

## How I'd get this ready for production

- Architecture: Implement View Model layer with proper DI for better testability.
  - Right now I use an Observable AudioPlayerManager which works well as a drop-in into the View for this prototype. In a production app, the View Model would help us test this functionality without loading SwiftUI views.
- Build previews and snapshot tests for our target devices so we can see this layout across different devices.
- Plug into a music provider, so we can use real tracks instead of the hard-coded demo tracks.
