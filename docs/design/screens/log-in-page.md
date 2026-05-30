# Log-In Page

**Source:** DesignImages/Log-In Page.png

## Purpose
Lets a returning user sign in with their email and password. Part of the auth flow, reached via the back arrow from a prior screen.

## Layout
- Status bar: standard mobile status bar at the top (time "9:41" left; signal, wifi, battery right) over the peach background.
- Header region: a back arrow ("<") in the top left.
- Title: "LOG IN" wordmark, centered in the upper area, in orange bubble lettering with a white outline.
- Mascot: a circular white badge containing the orange ukulele mascot, centered below the title.
- Body: two input fields stacked vertically, each as a label over an underline (no boxed border): "E-MAIL", "PASSWORD".
- Lower region: a primary "LOG IN" button centered below the fields, with a "Forgot your password?" text link beneath it.

## Components
- Back arrow icon (top left, orange).
- "LOG IN" title (orange bubble text, white outline).
- Circular mascot avatar (orange mascot on a white circle).
- "E-MAIL" text input (underline style).
- "PASSWORD" text input (underline style, obscured entry).
- Primary "LOG IN" button: orange filled, rounded corners, white bold label.
- "Forgot your password?" text link (muted/light color) below the button.

## Interactions / behavior
- Tapping the back arrow returns to the previous screen.
- Tapping a field focuses it and raises the keyboard; the label text acts as a placeholder/hint.
- The Password field obscures input.
- Tapping the "LOG IN" button validates the credentials and signs the user in, advancing to the home screen on success.
- Tapping "Forgot your password?" routes to a password-reset flow.

## Data shown
- Static: field labels/placeholders, button text, mascot, and the "Forgot your password?" link. Dynamic: the user-entered email and password values (and any inline error such as invalid credentials).

## Notes for implementation
- Color palette: peach/cream background, orange accents, orange filled primary button with white label; "Forgot your password?" is a low-emphasis light/muted link.
- Fields use the same minimalist underline style as the Sign-Up page; keep the two screens visually consistent.
- Title uses the brand bubble/sticker font with white outline.
- No "don't have an account / sign up" footer link is visible on this screen.
- Ambiguity: the password-reset destination and any inline error styling are not shown and should be defined in code.
