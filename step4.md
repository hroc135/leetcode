### Step 4
- step1~3ではスタックを自作する必要のあるGoを避けてPythonを使ったが、他の問題はGoで解いてきたのでGoでやることに。
- スタックも自作した

```Go
type runeStack []rune

func (s runeStack) Empty() bool { return len(s) == 0 }

func (s *runeStack) Push(r rune) {
    *s = append(*s, r)
}

func (s *runeStack) Pop() (rune, error) {
    l := len(*s)
    if l == 0 {
        return rune(0), errors.New("Empty Stack")
    }

    last := (*s)[l-1]
    *s = (*s)[:l-1]
    return last, nil
}

func isValid(s string) bool {
    openToClose := map[rune]rune{
        '(': ')',
        '{': '}',
        '[': ']',
    }
    openBracketStack := &runeStack{}

    for _, c := range s {
        if _, exist := openToClose[c]; exist {
            openBracketStack.Push(c)
            continue
        }

        last, err := openBracketStack.Pop()
        if err != nil || c != openToClose[last] {
            return false
        }
    }

    return openBracketStack.Empty()
}
```

- ちなみにスタックを自作せずスライスを使うと下のようになる。
- スタックを自作すると手間はかかるが、可読性は増すということを実感した

```Go
func isValid(s string) bool {
    openToClose := map[rune]rune{
        '(': ')',
        '{': '}',
        '[': ']',
    }
    openBracketStack := []rune{}

    for _, c := range s {
        if _, exist := openToClose[c]; exist {
            openBracketStack = append(openBracketStack, c)
            continue
        }
        l := len(openBracketStack)
        if l == 0 {
            return false
        }
        last := openBracketStack[l-1]
        openBracketStack = openBracketStack[:l-1]
        if c != openToClose[last] {
            return false
        }
    }

    return len(openBracketStack) == 0
}
```
