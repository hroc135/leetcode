Goで解いています。

### Step 1
- まず思いついたのは二重ループによる全探索
- 時間オーバーにならないかなと思い、入力の大きさを確認
- 最大入力は2e4なので、O(n^2)だと、2e4 * 2e4 / 1e8 = 4s で、GoだとCの倍くらい遅いので、見積もり最悪実行時間は8s。これだと時間制限に引っ掛かるだろう
- より速くできる方法を考える
- Sliding Windowを使った方法を思いついたが、負の値も含まれるリストなので結局全探索と同じ
  - 正の値しかないなら、インデックスを二つ保持して、x_iからx_jまでの和がkを超えた時点でx_iを右に一つずらす、というアルゴリズムでO(n)でできた
- いい方法を思いつかないので、ダメもとで全探索アルゴリズムを実装。すぐできた
- なんと通ってしまった。LeetCode上の実行時間は1.1s
- 空間計算量はO(1)

```Go
func subarraySum(nums []int, k int) int {
	res := 0

	for i := 0; i < len(nums); i++ {
		tmpSum := 0

		for j := i; j < len(nums); j++ {
			tmpSum += nums[j]
			if tmpSum == k {
				res++
			}
		}
	}

	return res
}
```

### Step 2
- 以下を参考にO(n)のアルゴリズムを実装してみる
  - https://github.com/seal-azarashi/leetcode/pull/16/files
  - https://github.com/fhiyo/leetcode/pull/19/files
- アルゴリズムを理解し、言語化してみる
  - インデックス0から累積和を計算していく
  - インデックスjで累積和がnになるとする
  - 累積和がn-kであるインデックスi（i<j）があるとすると、nums[i:j+1]の総和はk（n - (n-k) = k）である
  - という論理を使うと、累積和をキー、その累積和になった回数を値にもつマップを作り、逐一現在の累積和と照らし合わせれば、右端がnums[j]で総和kの部分配列の数がわかる
- step1の思考ログに記載した方法は、負の値に対応できないが、この方法なら、例えばk=1, nums=[1,-1,1,-1,1]という配列も漏れなく捌ける
- 空間計算量はO(n)
- https://google.github.io/styleguide/go/best-practices#size-hints に書いてあるようにマップのキャパシティを設定し、再ハッシュを防ぐ
- Goのmapで`mapName[key]`の返り値は1)値と,2)キーが存在するか否かのbool値の二つ
  - キーが存在しない場合、1)はマップのvalueのnil値を返す（今回はint型なので0）
  - Pythonのdefaultdictのようにデフォルト値を自分で設定できるような機能は少なくとも標準ライブラリでは用意されていない
- エラー処理した方が良さそうなところがあるかどうか考える
  - cumulativeSumのオーバーフローが気になったが、入力が負の値も含むので検知できない
  - ということで特に気を使うべきところはないだろう

```Go
func subarraySum(nums []int, k int) int {
	cumulativeSum := 0
	cumulativeSumCount := make(map[int]int, len(nums)+1)
	cumulativeSumCount[0] = 1
	res := 0

	for _, n := range nums {
		cumulativeSum += n
		res += cumulativeSumCount[cumulativeSum-k]  // returns nil (0) if key not found
		cumulativeSumCount[cumulativeSum]++
	}

	return res
}
```

### Step 3
- 修正箇所
  - res -> sumKSubarrays 宣言も一番最初にした（returnする値、つまり最も重要な変数なので）
- step2ではわかりやすさのため、マップの存在しないキーにアクセスした時の挙動についてのコメントを書いたが、Go開発者にとっては常識に含まれるだろうと思い、省いた

```Go
func subarraySum(nums []int, k int) int {
	sumKSubarrays := 0
	cumulativeSum := 0
	cumulativeSumFrequency := make(map[int]int, len(nums)+1)
	cumulativeSumFrequency[0] = 1

	for _, n := range nums {
		cumulativeSum += n
		sumKSubarrays += cumulativeSumFrequency[cumulativeSum-k]
		cumulativeSumFrequency[cumulativeSum]++
	}

	return sumKSubarrays
}
```
