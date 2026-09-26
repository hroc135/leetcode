- goでも解いてみました

```Go
func isValid(s string) bool {
    openToClose := map[rune]rune{
        '(': ')',
        '{': '}',
        '[': ']',
    }
    openBracketsStack := []rune{}

    for _, c := range s {
        if _, exist := openToClose[c]; exist {
            openBracketsStack = append(openBracketsStack, c)
            continue
        }

        l := len(openBracketsStack)
        if l == 0 {
            return false
        }

        top := openBracketsStack[l-1]
        openBracketsStack = openBracketsStack[:l-1]
        if c != openToClose[top] {
            return false
        }
    }

    return len(openBracketsStack) == 0
}
```
