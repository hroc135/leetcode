問題: https://leetcode.com/problems/string-to-integer-atoi/description/

### Step 1
- なんか帳尻合わせの汚いコードが出来上がった印象
- テストケース
    - s="" -> 0
    - s="1" -> 1
    - s="11" -> 11
    - s="1 01" -> 101
    - s="-1" -> -1
    - s="hello" -> 0
    - s="1hello56" -> 1
    - s="999999999999" -> math.MaxInt32

```Go
func myAtoi(s string) int {
	isNegative := false
	isNumber := false
	endParse := false
	var result int64
	for _, c := range s {
		switch {
		case unicode.IsLetter(c):
			endParse = true
		case !isNumber && c == ' ':
			continue
		case !isNumber && c == '-':
			isNegative = true
			isNumber = true
		case !isNumber && c == '+':
			isNegative = false
			isNumber = true
		case unicode.IsDigit(c):
			isNumber = true
			d := int64(c - '0')
			result = result*10 + d
			if isNegative && result > math.MaxInt32 {
				return math.MinInt32
			}
			if !isNegative && result >= math.MaxInt32 {
				return math.MaxInt32
			}
		default:
			endParse = true
		}
		if endParse {
			break
		}
	}
	if isNegative {
		return -int(result)
	}
	return int(result)
}
```

### Step 2
#### 2a
- https://github.com/olsen-blue/Arai60/pull/60/files#diff-f2b395d63173ac2f2d3c547e8f9e8e07c9acfbeb6b5da935bb28d83d8bcc7a04R141
    - step1 のようにまとめてやってしまうのではなく、誘導に従って一つずつ処理したほうがよっぽど見やすい
    - ワーキングメモリの話
- https://github.com/katsukii/leetcode/pull/9/files#diff-4ac2258a9828437ca7cab8fbd9970eecd069418f46ad2e8464424478e58a4ae4R202
    - オーバーフローの確認の仕方
    - なるほど、足す前に確認する方が、足した後に符号などで判定するより楽
- だいぶきれいに書けたので満足

```Go
func myAtoi(s string) int {
	index := 0
	for index < len(s) && s[index] == ' ' {
		index++
	}
	if index == len(s) {
		return 0
	}
	sign := 1
	if s[index] == '+' {
		index++
	} else if s[index] == '-' {
		sign = -1
		index++
	}
	result := 0
	for ; index < len(s); index++ {
		if !('0' <= s[index] && s[index] <= '9') {
			break
		}
		d := int(s[index] - '0')
		switch sign {
		case 1:
			if result > (math.MaxInt32-d)/10 {
				return math.MaxInt32
			}
			result = result*10 + d
		case -1:
			if result < (math.MinInt32+d)/10 {
				return math.MinInt32
			}
			result = result*10 - d
		}
	}
	return result
}
```

- マルチバイト文字が含まれている場合にどうなるか不安になった
    - 上記コードだとマルチバイト文字の先頭バイトが ' ', '-', '+' と一緒だとおかしなことになる
    - 調べたところ、マルチバイト文字は ascii と共存できるよう、先頭バイトは ascii の範囲外になるよう設計されているので、
    そういう問題は起きない

### Step 3

```Go
func myAtoi(s string) int {
	index := 0
	for index < len(s) && s[index] == ' ' {
		index++
	}
	if index == len(s) {
		return 0
	}

	sign := 1
	if s[index] == '+' {
		index++
	} else if s[index] == '-' {
		sign = -1
		index++
	}

	result := 0
	for ; index < len(s); index++ {
		if !('0' <= s[index] && s[index] <= '9') {
			break
		}
		d := int(s[index] - '0')
		switch sign {
		case 1:
			if result > (math.MaxInt32-d)/10 {
				return math.MaxInt32
			}
			result = result*10 + d
		case -1:
			if result < (math.MinInt32+d)/10 {
				return math.MinInt32
			}
			result = result*10 - d
		}
	}
	return result
}
```

### CS
- atoi
    - i は int なのでわかるが、なぜ a なのか疑問だったので調べた
    - https://stackoverflow.com/questions/2909768/where-did-the-name-atoi-come-from
    - a は ASCII から来ているらしい