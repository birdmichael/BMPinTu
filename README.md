# <img src="https://github.com/birdmichael/BMPinTu/blob/master/logo.jpg" width="50">BMPinTu
一个拼图demo，多边形拼图~

# 截图演示

[![img](https://github.com/birdmichael/BMPinTu/blob/master/123.gif)](https://github.com/birdmichael/BMPinTu/blob/master/123.gif)

# 项目特点

一款市面少见的拼图demo，很常见的是类似华容道一样的拼图，而不是类似贴图的拼图。

- 类似”魔法拼图“一样的拼图demo。
- 支持提示原图
- 支持自定义模块数量
- 注释即文档

# 代码说明

代码主逻辑步骤：

1. 初始化数据。
2. 创建切片类型，坐标，旋转属性
3. 创建贝塞尔曲线
4. 创建裁剪后的图片
5. 创建其他视图（顶部标题，求救按钮）

```
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeDataSet];
    [self setupPieceTypePieceCoordinateAndRotationValuesArrays];
    [self setUpPieceBezierPaths];
    [self setUpPuzzlePieceImages];
    [self setupOthersView];
}
```

切片类型：

```
typedef NS_ENUM(NSInteger, PieceType) {
    PieceTypeInside = -1,  // 凸
    PieceTypeEmpty, // 空（即边缘平整类型）
    PieceTypeOutside, // 凹
};
```

首先把一张原始图片切割为若干小图片，存放在`pieceTypeArray`数组，一张小图片有四个边，使用字典存储。

边类型：

```
typedef NS_ENUM(NSInteger, PieceSideType) {
    PieceSideTypeLeft = 0, // 左0
    PieceSideTypeTop,  // 上1
    PieceSideTypeRight, // 右2
    PieceSideTypeBottom, // 下3
    PieceSideTypeCount // 占位索引
};
```

## 创建小切片

1.双重`for`循环创建等大小切片

```
for(int i = 0; i < self.pieceVCount; i++) {
  for(int j = 0; j < self.pieceHCount; j++) {
  
  }
}
```

2.先定义中间切片边缘情况，上，右随机设置，下，左根据上一个为凸则为凹。

```
            if(j != 0) {
                mSideL = ([[[self.pieceTypeArray objectAtIndex:mCounter-1] objectForKey:@(PieceSideTypeRight)] intValue] == PieceTypeOutside)?PieceTypeInside:PieceTypeOutside;
            }
            if(i != 0){
                mSideB = ([[[self.pieceTypeArray objectAtIndex:mCounter-self.pieceHCount] objectForKey:@(PieceSideTypeTop)] intValue] == PieceTypeOutside)?PieceTypeInside:PieceTypeOutside;
            }
            // 随机凹凸
            mSideT = ((arc4random() % 2) == 1)?PieceTypeOutside:PieceTypeInside;
            mSideR = ((arc4random() % 2) == 1)?PieceTypeOutside:PieceTypeInside;
```

3.定义边缘为直线。

```
            if(i == 0) {
                mSideB = PieceTypeEmpty;
            }
            if(j == 0) {
                mSideL = PieceTypeEmpty;
            }
            if(i == self.pieceVCount-1) {
                mSideT = PieceTypeEmpty;
            }
            if(j == self.pieceHCount - 1) {
                mSideR = PieceTypeEmpty;
            }
```

4.根据类型是凹还是凸，进行尺寸修正。凸的会多一个`deepnessV`或`deepnessH`

```
            if(mSideL == PieceTypeOutside) {
                mCubeWidth -= self.deepnessV;
            }
            if(mSideR == PieceTypeOutside) {
                mCubeWidth -= self.deepnessV;
            }
            if(mSideT == PieceTypeOutside) {
                mCubeHeight -= self.deepnessH;
            }
            if(mSideB == PieceTypeOutside) {
                mCubeHeight -= self.deepnessH;
            }
```

5.填装切块类型数组

```
            NSMutableDictionary *mOnePieceDic = [@{} mutableCopy];

            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideL] forKey:@(PieceSideTypeLeft)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideB] forKey:@(PieceSideTypeBottom)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideT] forKey:@(PieceSideTypeTop)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideR] forKey:@(PieceSideTypeRight)];
            
            [self.pieceTypeArray addObject:mOnePieceDic];
```

6.填装尺寸及方向（默认一个方向）数组，并使索引计数器自增。

# TODO:

1. 支持旋转，并在验证添加旋转是否相等验证。
2. 手势停止后悬停在网格中，而非任意位置。
3. 使用`UIScrollView`装载模块，并切换父视图。

