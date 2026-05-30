# Sign-Up Page

**Source:** DesignImages/Sign-Up Page.png

## Purpose
Lets a new user create an account by entering an email and password. Part of the auth flow, reached via the back arrow from a prior screen.

## Layout
- Status bar: standard mobile status bar at the top (time "9:41" left; signal, wifi, battery right) over the peach background.
- Header region: a back arrow ("<") in the top left.
- Title: "SIGN UP" wordmark, centered in the upper area, in orange bubble lettering with a white outline.
- Body: three input fields stacked vertically, each rendered as a label over an underline (no boxed border): "E-MAIL", "PASSWORD", "REPEAT PASSWORD".
- Lower region: a single primary "SIGN UP" button, centered, below the fields.

## Components
- Back arrow icon (top left, orange).
- "SIGN UP" title (orange bubble text, white outline).
- "E-MAIL" text input (underline style).
- "PASSWORD" text input (underline style, obscured entry).
- "REPEAT PASSWORD" text input (underline style, obscured entry, for confirmation).
- Primary "SIGN UP" button: orange filled, rounded corners, white bold label.

## Interactions / behavior
- Tapping the back arrow returns to the previous screen.
- Tapping a field focuses it and raises the keyboard; the label text acts as a placeholder/hint.
- Password and Repeat Password fields obscure input.
- Tapping the "SIGN UP" button validates the fields (including that password and repeat-password match) and submits to create the account.

## Data shown
- Static: field labels/placeholders and the button text. Dynamic: the user-entered email and password values (and any inline validation/mismatch messages).

## Notes for implementation
- Color palette: peach/cream background, orange accents, orange filled primary button with white label.
- Fields use a minimalist underline style (light label text, thin underline rule), not boxed inputs; consistent vertical spacing between the three.
- Title uses the brand bubble/sticker font with white outline, matching splash and other screens.
- No mascot image, no name field, and no "already have an account / log in" footer link are visible on this screen.
- Ambiguity: client-side validation rules (password strength, email format) are not shown and should be defined in code.
