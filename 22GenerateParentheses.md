問題: https://leetcode.com/problems/generate-parentheses/description/

### Step 1
- 手でやることをコードで再現したらできた。嬉しい。成長を感じる
- 手でやったところ、n=i で生成された parenthesis を基に n=i+1 のものを生成するが、
どうしても重複なく生成する方法を思いつかなかったので、map に格納していくことにした
- "(())" を基に次の parenthesis を生成するなら、頭と末尾に "()" を付けたやつ（"()(())", "(())()"）と、
'(' の後ろに "()" を付けたやつ（"(()())", "((()))"）を生成できる。
- Go の string はイミュータブルなのでコピーするコードを書かなくて済んだ。
- 時間計算量と空間計算量の求め方がわからん
    - 一応立てた漸化式はこんな感じ
    - T(n) = T(n-1) + p(n-1) × 2(n-1)
    - p(i) は n=i のときに生成されたユニークな parenthesis の個数
- カタラン数というもので抑えられるらしい
    - https://github.com/frinfo702/software-engineering-association/pull/10#discussion_r1881386807
- 他の解法も考えてみる。再帰に直すことはできそう。他のロジックは思いつかない

```Go
func generateParenthesis(n int) []string {
    if n == 0 {
        return []string{}
    }
    parenthesis := map[string]struct{}{"()": {}}
    for i := 2; i <= n; i++ {
        nextParenthesis := make(map[string]struct{})
        for p := range parenthesis {
            newParenthesis := "()" + p
            nextParenthesis[newParenthesis] = struct{}{}
            for j := range len(p) {
                if p[j] == '(' {
                    newParenthesis = p[:j+1] + "()" + p[j+1:]
                    nextParenthesis[newParenthesis] = struct{}{}
                }
            }
            newParenthesis = p + "()"
            nextParenthesis[newParenthesis] = struct{}{}
        }
        parenthesis = nextParenthesis
    }
    result := []string{}
    for k := range parenthesis {
        result = append(result, k)
    }
    return result
}
```

### Step 2
#### 2a
- step1 の修正
- Go1.23 からイテレータが使えるようになったので、使ってみる（map.Keys）

```Go
func generateParenthesis(n int) []string {
	if n == 0 {
		return []string{}
	}
	parenthesis := map[string]struct{}{"()": {}}
	for i := 2; i <= n; i++ {
		nextParenthesis := make(map[string]struct{})
		for p := range maps.Keys(parenthesis) {
			nextParenthesis["()"+p] = struct{}{}
			nextParenthesis[p+"()"] = struct{}{}
			for j := range len(p) {
				if p[j] == '(' {
					newP := p[:j+1] + "()" + p[j+1:]
					nextParenthesis[newP] = struct{}{}
				}
			}
		}
		parenthesis = nextParenthesis
	}
	result := []string{}
	for p := range maps.Keys(parenthesis) {
		result = append(result, p)
	}
	return result
}
```

#### 2b
- 2a を再帰に直した

```Go
func generateParenthesis(n int) []string {
	if n == 0 {
		return []string{}
	}
	if n == 1 {
		return []string{"()"}
	}
	previousParenthesis := generateParenthesis(n - 1)
	parenthesisSet := make(map[string]struct{})
	for _, p := range previousParenthesis {
		parenthesisSet["()"+p] = struct{}{}
		parenthesisSet[p+"()"] = struct{}{}
		for i := range len(p) {
			if p[i] == '(' {
				newP := p[:i+1] + "()" + p[i+1:]
				parenthesisSet[newP] = struct{}{}
			}
		}
	}
	parenthesis := []string{}
	for p := range maps.Keys(parenthesisSet) {
		parenthesis = append(parenthesis, p)
	}
	return parenthesis
}
```

#### 2c
- https://discord.com/channels/1084280443945353267/1201211204547383386/1230529256358940722
    - 括弧を前から構築していっている
- なるほど、')' は '(' の個数の方が多いときにしか追加できないことを利用している

```Go
func generateParenthesis(n int) []string {
	type parenthesisBuilder struct {
		parenthesis string
		leftCount   int // leftCount indicates the number of '(' included in parenthesis
		rightCount  int
	}
	stack := []parenthesisBuilder{{"", 0, 0}}
	result := []string{}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		parenthesis, leftCount, rightCount := top.parenthesis, top.leftCount, top.rightCount
		if leftCount == n && rightCount == n {
			result = append(result, parenthesis)
			continue
		}
		if leftCount < n {
			stack = append(stack, parenthesisBuilder{parenthesis + "(", leftCount + 1, rightCount})
		}
		if rightCount < leftCount {
			stack = append(stack, parenthesisBuilder{parenthesis + ")", leftCount, rightCount + 1})
		}
	}
	return result
}
```

#### 2d
- https://github.com/olsen-blue/Arai60/pull/54/files#diff-f09bc4caa2343f04592a1bdcc48b3303c4f95bfa6f334c126dc596850115384eR244
- これぞバックトラック
- parenthesis を rune 型のスライスで管理することによって、イミュータブルな string より計算コストを削減できた
（毎回コピーする必要がなくなった）

```Go
func generateParenthesis(n int) []string {
	result := []string{}
	parenthesis := []rune{}

	var generateParenthesisHelper func(int, int)
	generateParenthesisHelper = func(leftCount, rightCount int) {
		if leftCount == n && rightCount == n {
			result = append(result, string(parenthesis))
			return
		}
		if leftCount < n {
			parenthesis = append(parenthesis, '(')
			generateParenthesisHelper(leftCount+1, rightCount)
			parenthesis = parenthesis[:len(parenthesis)-1]
		}
		if rightCount < leftCount {
			parenthesis = append(parenthesis, ')')
			generateParenthesisHelper(leftCount, rightCount+1)
			parenthesis = parenthesis[:len(parenthesis)-1]
		}
	}

	generateParenthesisHelper(0, 0)
	return result
}
```

#### 2e
- https://github.com/olsen-blue/Arai60/pull/54/files#diff-f09bc4caa2343f04592a1bdcc48b3303c4f95bfa6f334c126dc596850115384eR303
    - おお！感動
- 問題の分解の仕方を変えるだけでこんなにすっきり書けてしまうとは
- https://sentry.io/answers/concatenating-strings-in-go/
    - strings.Builder で用意したバッファに WriteString で書き込むとコピーせずに string を結合できるらしい
    - 可読性は落ちたと思う

```Go
func generateParenthesis(n int) []string {
	if n == 0 {
		return []string{""}
	}
	result := []string{}
	for i := range n {
		for _, a := range generateParenthesis(i) {
			for _, b := range generateParenthesis(n - i - 1) {
				var p strings.Builder
				p.WriteString("(")
				p.WriteString(a)
				p.WriteString(")")
				p.WriteString(b)
				result = append(result, p.String())
			}
		}
	}
	return result
}
```

### Step 3

```Go
func generateParenthesis(n int) []string {
	if n == 0 {
		return []string{""}
	}
	result := []string{}
	for i := range n {
		for _, a := range generateParenthesis(i) {
			for _, b := range generateParenthesis(n - i - 1) {
				var p strings.Builder
				p.WriteString("(")
				p.WriteString(a)
				p.WriteString(")")
				p.WriteString(b)
				result = append(result, p.String())
			}
		}
	}
	return result
}
```

### CS