### Step 1
- stackのカテゴリの問題であるというヒントもあり、すぐに方針は立った
- 実装も割とすぐにできた
- 他のArai60の問題はgolangで解いてきたが、golangでの文字列処理は面倒なのでPythonを使うことにした

```Python3
class Solution:
    def isValid(self, s: str) -> bool:
        brackets = {
            ")": "(",
            "}": "{",
            "]": "["
        }
        stack: List[str] = []
        for i in range(len(s)):
            if s[i] in brackets.keys():
                if len(stack) == 0:
                    return False
                c = stack.pop()
                if brackets[s[i]] != c:
                    return False
            else:
                stack.append(s[i])
        return len(stack) == 0
```

### Step 2
- コードを整えつつ、discordで先人達のコードも参考にした
- close_to_openのマップよりopen_to_closeを使っているコードを多く見たのでそちらを試してみる
  - if文をネストさせずに済んだのでこっちの方が良いだろう
- Pythonの好きでない点として、同じことをやろうとしても選択肢が多すぎるという点を挙げられるが、今回もまさしくそう
  - スタックを普通のリストを使って実現するか、deque()を使うか、LifoQueueを使うか、、
  - 下記コードのようにLifoQueueを使うと、宣言時にこれはスタックであるということをリスト名にstackという言葉を入れなくてもわかるのが利点。欠点としては、メソッドがput, getでスタックぽくない
  - 逆にリストやdeque()を使うと、スタックであるということを別の方法(命名やコメント)で伝えないといけなかったり、誤ってスタックではしない動作をさせてしまう可能性があるのが難点

```Python3
from queue import LifoQueue


class Solution:
    def isValid(self, s: str) -> bool:
        open_to_close = {
            "(": ")",
            "{": "}",
            "[": "]"
        }
        open_brackets = LifoQueue()
        
        for i in range(len(s)):
            if s[i] in open_to_close:
                open_brackets.put(s[i])
                continue
            if open_brackets.empty():
                return False
            c = open_brackets.get()
            if s[i] != open_to_close[c]:
                return False
        
        return open_brackets.empty()
```

### Step 3
- `for i in range(len(s))`を`for c in s`に変えて、Pythonらしくシンプルさを追求した
- `if c in open_to_close.keys()`もより短く`if c in open_to_close`に変えた

```Python3
from queue import LifoQueue


class Solution:
    def isValid(self, s: str) -> bool:
        open_to_close = {
            "(": ")",
            "{": "}",
            "[": "]"
        }
        open_brackets = LifoQueue()

        for c in s:
            if c in open_to_close:
                open_brackets.put(c)
                continue
            if open_brackets.empty():
                return False
            top = open_brackets.get()
            if c != open_to_close[top]:
                return False
        
        return open_brackets.empty()
```
