### Step 1
- まず考えたのは、emailを最も単純な形に変換し、単純化されたメールアドレスを集合に溜めていき、最終的に集合の中の要素数を返す方法
- テストで2回こけた
  - 実装はスムーズに進んだが、メアドを単純化する部分の処理の順番が間違っており、ドメインが返されないようになってしまっていたので修正
  - `for _, _ := range simplifiedEmails`としていたが、新しく宣言している変数がないので、`:=`ではなく、`=`にしないといけなかった
- [Googleのスタイルガイド](https://google.github.io/styleguide/go/decisions)に
> Omit types and type-like words from most variable names.
For a number, userCount is a better name than numUsers or usersInt.

とあったので、`distinctSimplifiedEmailsNum`としようとしたところを`distinctSimplifiedEmails`とした
- 時間計算量：O(n) （n: len(emails)）
  - メアドの長さをmとしてO(nm)としたいところだが、[RFC 5321](https://www.rfc-editor.org/rfc/rfc5321#section-4.5.3)によると、メアドの長さは高々320字で無視できる大きさなのでO(n)
  - 見積もり実行時間：100 * 100 / 10^8 = 10^-4 = 0.1ms
- 空間計算量：O(n)

```Go
// Go

func numUniqueEmails(emails []string) int {
	simplifiedEmails := make(map[string]struct{})
	for _, email := range emails {
		email := simplifyEmailAddress(email)
		simplifiedEmails[email] = struct{}{}
	}

	distinctSimplifiedEmails := 0
	for _, _ = range simplifiedEmails {
		distinctSimplifiedEmails++
	}
	return distinctSimplifiedEmails
}

func simplifyEmailAddress(email string) string {
	simplifiedEmail := ""
	localOrDomain := "local"
	afterPlusMark := false

	for _, c := range email {
		if c == '@' {
			localOrDomain = "domain"
		}
		if localOrDomain == "local" && (afterPlusMark || c == '.') {
			continue
		}
		if localOrDomain == "local" && c == '+' {
			afterPlusMark = true
			continue
		}

		simplifiedEmail += string(c)
	}

	return simplifiedEmail
}
```

### Step 2
- step1のコードの修正
- `simplifiedEmail` -> `simplified` （関数名simplifyEmailAddressから`var simplified string`だけで役割が推測できるから）
- 単純化されたメアドの集合を作るループと`uniqueEmails`を数えるループを合体

```Go
func numUniqueEmails(emails []string) int {
	simplifiedEmails := make(map[string]struct{})

	for _, email := range emails {
		email := simplifyEmailAddress(email)
		simplifiedEmails[email] = struct{}{}
	}

	return len(simplifiedEmails)
}

func simplifyEmailAddress(email string) string {
	var simplified string
	localOrDomain := "local"
	afterPlusMark := false

	for _, c := range email {
		if c == '@' {
			localOrDomain = "domain"
		}
		if localOrDomain == "local" && afterPlusMark {
			continue
		}
		if localOrDomain == "local" && c == '.' {
			continue
		}
		if localOrDomain == "local" && c == '+' {
			afterPlusMark = true
			continue
		}

		simplified += string(c)
	}

	return simplified
}
```

- 有効なメアドかどうかを確かめるコードも追加
- 他の人の回答を見ていたらlocal nameとdomain nameに分けて処理している人が多く、その方がコードもわかりやすくなるだろうと思い、真似た
  - このほうが有効なメアドかどうかの判定もしやすい
- 以下リンクによると、エラー文に大文字は使わない
  - https://staticcheck.dev/docs/checks/#ST1005

```Go
func numUniqueEmails(emails []string) int {
	simplifiedEmails := make(map[string]struct{})

	for _, email := range emails {
		simplified, err := simplifyEmailAddress(email)
		if err != nil {
			panic(fmt.Sprintf("%s is an invalid email: %v", email, err))
		}
		simplifiedEmails[simplified] = struct{}{}
	}

	return len(simplifiedEmails)
}

func simplifyEmailAddress(email string) (string, error) {
	localAndDomain := strings.Split(email, "@")
	if len(localAndDomain) != 2 {
		return "", errors.New("too many '@'")
	}

	local, domain := localAndDomain[0], localAndDomain[1]
	if len(local) == 0 {
		return "", errors.New("local name is empty")
	}
	if local[0] == '+' {
		return "", errors.New("local name starts with '+'")
	}
	if len(domain) == 0 {
		return "", errors.New("domain name is empty")
	}
	if len(domain) < 4 || domain[len(domain)-4:] == ".com" {
		return "", errors.New("domain name doesn't end with '.com'")
	}

	var simplifiedLocal string

	for _, c := range local {
		if c == '.' {
			continue
		}
		if c == '+' {
			break
		}
		if c < 'a' && c > 'z' {
			return "", errors.New("contains invalid character")
		}

		simplifiedLocal += string(c)
	}

	return simplifiedLocal + "@" + domain, nil
}
```

- 標準ライブラリのstringsを使って解く
- 時間計算量はstep1の解法と同じO(n)のはずなのにこちらの方がleetcodeの計測時間が1/3くらいになるのは標準ライブラリの最適化のおかげ？

```Go
func numUniqueEmails(emails []string) int {
	addresses := make(map[string]struct{})

	for _, email := range emails {
		localAndDomain := strings.Split(email, "@")
		localName, domainName := localAndDomain[0], localAndDomain[1]

		indexOfPlus := strings.Index(localName, "+")
		if indexOfPlus != -1 {
			localName = localName[:indexOfPlus]
		}
		localName = strings.ReplaceAll(localName, ".", "")

		actualAddress := localName + "@" + domainName
		addresses[actualAddress] = struct{}{}
	}

	return len(addresses)
}
```

- https://github.com/TORUS0818/leetcode/pull/16/files を参考に、正規表現を使う方法も試してみることに
- https://help.xmatters.com/ondemand/trial/valid_email_format.htm 有効なメアドの条件について
  - local: アルファベットと数字以外に、'_', '.', '/'が使える
  - domain: アルファベット、数字、'.', '/'が使える。最後の'.'以下は、2字以上でないといけない

```Go
func numUniqueEmails(emails []string) int {
	emailRegexp := regexp.MustCompile(`([^+]+)(?:\+.*)?@(.+)`)

	uniqueAddresses := make(map[string]struct{})

	for _, email := range emails {
		localAndDomain := emailRegexp.FindStringSubmatch(email)
		localName := strings.ReplaceAll(localAndDomain[1], ".", "")
		domainName := localAndDomain[2]
		normalized := localName + "@" + domainName

		uniqueAddresses[normalized] = struct{}{}
	}

	return len(uniqueAddresses)
}
```

### Step 3
```Go
func numUniqueEmails(emails []string) int {
	uniqueAddresses := make(map[string]struct{})

	for _, email := range emails {
		localAndDomain := strings.Split(email, "@")
		if len(localAndDomain) != 2 {
			return -1 // 本当は関数の返り値をint, errorにしてerrorを返したいところ
		}
		localName, domainName := localAndDomain[0], localAndDomain[1]

		localName = strings.Split(localName, "+")[0]
		localName = strings.ReplaceAll(localName, ".", "")

		normalized := localName + "@" + domainName
		uniqueAddresses[normalized] = struct{}{}
	}

	return len(uniqueAddresses)
}
```
