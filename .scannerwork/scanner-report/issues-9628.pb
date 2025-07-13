t

typescriptS6819UUse <dialog> instead of the "dialog" role to ensure accessibility across all devices.2 	â

typescriptS6848ÂAvoid non-native interactive elements. If using native HTML is not possible, add an appropriate role and support for tabbing, mouse, keyboard, and touch inputs to an interactive content element.2,4 ~

typescriptS1082_Visible, non-interactive elements with click handlers must have at least one keyboard listener.2,4 å

typescriptS6851ÅRedundant alt attribute. Screen-readers already announce `img` tags as an image. You don\u8217t need to use the words `image`, `photo,` or `picture` (or any specified custom words) in the alt prop.259  