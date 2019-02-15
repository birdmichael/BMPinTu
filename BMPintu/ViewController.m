//
//  ViewController.m
//  BMPintu
//
//  Created by BirdMichael on 2019/2/14.
//  Copyright © 2019 BirdMichael. All rights reserved.
//

#import "ViewController.h"
#import "UIView+Additions.h"

static const CGFloat kVerificationTolerance = 8.0; // 验证容错值

typedef NS_ENUM(NSInteger, PieceType) {
    PieceTypeInside = -1,  // 凸
    PieceTypeEmpty, // 空（即边缘平整类型）
    PieceTypeOutside, // 凹
};
typedef NS_ENUM(NSInteger, PieceSideType) {
    PieceSideTypeLeft = 0, // 左0
    PieceSideTypeTop,  // 上1
    PieceSideTypeRight, // 右2
    PieceSideTypeBottom, // 下3
    PieceSideTypeCount // 占位索引
};

@interface ViewController () <UIGestureRecognizerDelegate>

// 原始图片
@property (nonatomic, strong) UIImage *originalCatImage;
/** 水平切片数量 */
@property (nonatomic, assign) NSUInteger pieceHCount;
/** 垂直切片数量 */
@property (nonatomic, assign) NSUInteger pieceVCount;
/** 方格模块高度值 */
@property (nonatomic, assign) NSInteger cubeHeightValue;
/** 方格模块宽度值 */
@property (nonatomic, assign) NSInteger cubeWidthValue;
/** 水平深度 */
@property (nonatomic, assign) NSInteger deepnessH;
/** 垂直深度 */
@property (nonatomic, assign) NSInteger deepnessV;

/** 切片类型数组 */
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pieceTypeArray;
/** 切片坐标 */
@property (nonatomic, strong) NSMutableArray *pieceCoordinateRectArray;
/** 切片坐标 */
//@property (nonatomic, strong) NSMutableArray *pieceCoordinateBoundsArray;
/** 切片方向 */
@property (nonatomic, strong) NSMutableArray *pieceRotationArray;

/** 切片完整贝塞尔曲线 */
@property (nonatomic, strong) NSMutableArray *pieceBezierPathsArray;

@property (nonatomic, assign) CGFloat firstX;
@property (nonatomic, assign) CGFloat firstY;

@property (nonatomic, strong) UIImageView *tipsImgaeView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeDataSet];
    [self setupPieceTypePieceCoordinateAndRotationValuesArrays];
    [self setUpPieceBezierPaths];
    [self setUpPuzzlePieceImages];
    [self setupOthersView];
}

#pragma mark ——— 私有方法
/** 设置页面视图 */
- (void)setupOthersView {
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    logo.top = 44;
    logo.size = CGSizeMake(80, 80);
    logo.centerX = self.view.centerX;
    [self.view addSubview:logo];
    
    UILabel *title = [UILabel new];
    [self.view addSubview:title];
    title.text = @"BMPinTu";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = [UIColor blackColor];
    title.top = logo.bottom ;
    title.size = CGSizeMake(200, 20);
    title.textAlignment = NSTextAlignmentCenter;
    title.centerX = logo.centerX;
    
    UIButton *tipBtn = [UIButton new];
    [tipBtn setTitle:@"求救BM" forState:UIControlStateNormal];
    [tipBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:tipBtn];
    [tipBtn setBackgroundColor:[UIColor blackColor]];
    tipBtn.size = CGSizeMake(120, 40);
    tipBtn.centerX = logo.centerX;
    tipBtn.top = self.tipsImgaeView.bottom + 80;
    tipBtn.layer.cornerRadius = 5;
    [tipBtn addTarget:self action:@selector(showTip) forControlEvents:UIControlEventTouchDown];
    [tipBtn addTarget:self action:@selector(hideTip) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    
}

- (void)showTip {
    self.tipsImgaeView.image = [UIImage imageNamed:@"123"];
    self.tipsImgaeView.alpha = 0.5;
}
- (void)hideTip {
    self.tipsImgaeView.image = nil;
    self.tipsImgaeView.alpha = 1;
}

/** 设置初始化数据 */
- (void)initializeDataSet {
    //创建提示图像，（位置以及尺寸决定拼图位置以及尺寸）
    self.tipsImgaeView = [UIImageView new];
    self.tipsImgaeView.size = CGSizeMake([[UIScreen mainScreen] bounds].size.width - 3, [[UIScreen mainScreen] bounds].size.width -3);
    self.tipsImgaeView.centerX = self.view.centerX;
    self.tipsImgaeView.centerY = self.view.centerY;
    [self.view addSubview:self.tipsImgaeView];
//    self.tipsImgaeView.image = [UIImage imageNamed:@"123"];
    self.tipsImgaeView.layer.borderColor = [UIColor blackColor].CGColor;
    self.tipsImgaeView.layer.borderWidth = 1;
    
    
    self.originalCatImage = [self imageResize:[UIImage imageNamed:@"123"] andResizeTo:self.tipsImgaeView.frame.size];
    // 切片数量
    self.pieceHCount = 3;
    self.pieceVCount = 3;
    // 切片尺寸
    self.cubeHeightValue = self.originalCatImage.size.height/self.pieceHCount;
    self.cubeWidthValue = self.originalCatImage.size.width/self.pieceVCount;
    // 设置深度（凹凸）
    self.deepnessH = -(self.cubeHeightValue / 4);
    self.deepnessV = -(self.cubeWidthValue / 4);
    
    // 初始化组数容器
    self.pieceTypeArray = [@[] mutableCopy];
    self.pieceCoordinateRectArray = [@[] mutableCopy];
//    self.pieceCoordinateBoundsArray = [@[] mutableCopy];
    self.pieceRotationArray = [@[] mutableCopy];
    self.pieceBezierPathsArray = [@[] mutableCopy];
    
}

/** 设置Piece切片的类型，坐标，以及方向 */
- (void)setupPieceTypePieceCoordinateAndRotationValuesArrays {
    
    NSUInteger mCounter = 0; // 调用计数器
    
    PieceType mSideL = PieceTypeEmpty;
    PieceType mSideT = PieceTypeEmpty;
    PieceType mSideR = PieceTypeEmpty;
    PieceType mSideB = PieceTypeEmpty;
    
    NSUInteger mCubeWidth = 0;
    NSUInteger mCubeHeight = 0;
    
    // 构建2维 i为垂直，j为水平
    for(int i = 0; i < self.pieceVCount; i++) {
        for(int j = 0; j < self.pieceHCount; j++) {
            // 1.设置类型
            
            // 1.1 中间 保证一凸一凹
            if(j != 0) {
                mSideL = ([[[self.pieceTypeArray objectAtIndex:mCounter-1] objectForKey:@(PieceSideTypeRight)] intValue] == PieceTypeOutside)?PieceTypeInside:PieceTypeOutside;
            }
            if(i != 0){
                mSideB = ([[[self.pieceTypeArray objectAtIndex:mCounter-self.pieceHCount] objectForKey:@(PieceSideTypeTop)] intValue] == PieceTypeOutside)?PieceTypeInside:PieceTypeOutside;
            }
            // 随机凹凸
            mSideT = ((arc4random() % 2) == 1)?PieceTypeOutside:PieceTypeInside;
            mSideR = ((arc4random() % 2) == 1)?PieceTypeOutside:PieceTypeInside;
            
            // 1.2 边
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
            
            // 2.设置高度以及宽度
            // 2.1 重置数据
            mCubeWidth = self.cubeWidthValue;
            mCubeHeight = self.cubeHeightValue;
            // 2.2 根据凹凸 进行数据修正
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
            
            // 3. 组装类型数组
            NSMutableDictionary *mOnePieceDic = [@{} mutableCopy];

            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideL] forKey:@(PieceSideTypeLeft)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideB] forKey:@(PieceSideTypeBottom)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideT] forKey:@(PieceSideTypeTop)];
            [mOnePieceDic setObject:[NSNumber numberWithInteger:mSideR] forKey:@(PieceSideTypeRight)];
            
            [self.pieceTypeArray addObject:mOnePieceDic];
            
            // 4. 组装裁剪和图像用的 frame 和 bouns
            CGFloat mStartPointX = self.tipsImgaeView.left;
            CGFloat mStartPointY = self.tipsImgaeView.top;
            [self.pieceCoordinateRectArray addObject:[NSArray arrayWithObjects:
                                                  [NSValue valueWithCGRect:CGRectMake(j*self.cubeWidthValue,  i*self.cubeHeightValue,mCubeWidth,mCubeHeight)],
                                                  [NSValue valueWithCGRect:CGRectMake(mStartPointX +j*self.cubeWidthValue-(mSideL == PieceTypeOutside?-self.deepnessV:0),mStartPointY + i*self.cubeHeightValue-(mSideB == PieceTypeOutside?-self.deepnessH:0), mCubeWidth, mCubeHeight)], nil]];
            
            
            
            [self.pieceRotationArray addObject:[NSNumber numberWithFloat:0]];
            mCounter++;
        }
    }
}

// 设置贝塞尔曲线
- (void)setUpPieceBezierPaths {
    // 1. 初始化临时数据
    float mYSideStartPos = 0; // Y边起点
    float mXSideStartPos = 0; // x边起点
    float mCustomDeepness = 0; // 深度。
    float mCurveHalfVLength = self.cubeWidthValue / 10;
    float mCurveHalfHLength = self.cubeHeightValue / 10;
    float mCurveStartXPos = self.cubeWidthValue / 2 - mCurveHalfVLength;
    float mCurveStartYPos = self.cubeHeightValue / 2 - mCurveHalfHLength;
    float mTotalHeight = 0; // 总高
    float mTotalWidth = 0; // 总宽
    
    // 2. 根据类型数据制作贝塞尔曲线
    for(int i = 0; i < [self.pieceTypeArray count]; i++) {
        // 2.1 根绝检测左边和下边是否凹决定起点
        mXSideStartPos = ([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeLeft)] integerValue] == PieceTypeOutside)?-self.deepnessV:0;
        mYSideStartPos = ([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeBottom)] integerValue] == PieceTypeOutside)?-self.deepnessH:0;
        
        
        mTotalHeight = mYSideStartPos + mCurveStartYPos*2 + mCurveHalfHLength * 2;
        mTotalWidth = mXSideStartPos + mCurveStartXPos*2 + mCurveHalfVLength * 2;
        
        
        //2.2 初始化一条含凹凸的贝塞尔曲线
        UIBezierPath* mPieceBezier = [UIBezierPath bezierPath];
        [mPieceBezier moveToPoint: CGPointMake(mXSideStartPos, mYSideStartPos)];
        
        //2.2.2 绘制Left
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos, mYSideStartPos + mCurveStartYPos)];
        
        if([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeLeft)] integerValue] != PieceTypeEmpty) {
            mCustomDeepness = self.deepnessV * [[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeLeft)] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCustomDeepness, mYSideStartPos + mCurveStartYPos+mCurveHalfHLength) controlPoint1: CGPointMake(mXSideStartPos, mYSideStartPos + mCurveStartYPos) controlPoint2: CGPointMake(mXSideStartPos + mCustomDeepness, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength - mCurveStartYPos)];//25PieceTypeEmpty
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength*2) controlPoint1: CGPointMake(mXSideStartPos + mCustomDeepness, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength + mCurveStartYPos) controlPoint2: CGPointMake(mXSideStartPos, mYSideStartPos+mCurveStartYPos + mCurveHalfHLength*2)]; //156
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos, mTotalHeight)];
  
        //2.2.2 绘制Top
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos+ mCurveStartXPos, mTotalHeight)];
        if([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeTop)] integerValue] != PieceTypeEmpty) {
            mCustomDeepness = self.deepnessH * [[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeTop)] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCurveStartXPos + mCurveHalfVLength, mTotalHeight - mCustomDeepness) controlPoint1: CGPointMake(mXSideStartPos + mCurveStartXPos, mTotalHeight) controlPoint2: CGPointMake(mXSideStartPos + mCurveHalfVLength, mTotalHeight - mCustomDeepness)];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCurveStartXPos + mCurveHalfVLength+mCurveHalfVLength, mTotalHeight) controlPoint1: CGPointMake(mTotalWidth - mCurveHalfVLength, mTotalHeight - mCustomDeepness) controlPoint2: CGPointMake(mXSideStartPos + mCurveStartXPos + mCurveHalfVLength + mCurveHalfVLength, mTotalHeight)];
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth, mTotalHeight)];

        
        //2.2.3 绘制Right
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth, mTotalHeight - mCurveStartYPos)];
        if([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeRight)] integerValue] != PieceTypeEmpty) {
            mCustomDeepness = self.deepnessV * [[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeRight)] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mTotalWidth - mCustomDeepness, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength) controlPoint1: CGPointMake(mTotalWidth, mYSideStartPos + mCurveStartYPos + mCurveHalfHLength * 2) controlPoint2: CGPointMake(mTotalWidth - mCustomDeepness, mTotalHeight - mCurveHalfHLength)];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mTotalWidth, mYSideStartPos + mCurveStartYPos) controlPoint1: CGPointMake(mTotalWidth - mCustomDeepness, mYSideStartPos + mCurveHalfHLength) controlPoint2: CGPointMake(mTotalWidth, mCurveStartYPos + mYSideStartPos)];
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth, mYSideStartPos)];
        
        
        //2.2.3 绘制Bottom
        [mPieceBezier addLineToPoint: CGPointMake(mTotalWidth - mCurveStartXPos, mYSideStartPos)];
        if([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeBottom)] integerValue] != PieceTypeEmpty) {
            mCustomDeepness = self.deepnessH * [[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeBottom)] intValue];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mTotalWidth - mCurveStartXPos - mCurveHalfVLength, mYSideStartPos + mCustomDeepness) controlPoint1: CGPointMake(mTotalWidth - mCurveStartXPos, mYSideStartPos) controlPoint2: CGPointMake(mTotalWidth - mCurveHalfVLength, mYSideStartPos + mCustomDeepness)];
            
            [mPieceBezier addCurveToPoint: CGPointMake(mXSideStartPos + mCurveStartXPos, mYSideStartPos) controlPoint1: CGPointMake(mXSideStartPos + mCurveHalfVLength, mYSideStartPos + mCustomDeepness) controlPoint2: CGPointMake(mXSideStartPos + mCurveStartXPos, mYSideStartPos)];
        }
        
        [mPieceBezier addLineToPoint: CGPointMake(mXSideStartPos, mYSideStartPos)];
        
        
  
        [self.pieceBezierPathsArray addObject:mPieceBezier];
        
    }
}

- (void)setUpPuzzlePieceImages {
    float mXAddableVal = 0;
    float mYAddableVal = 0;
    
    for(int i = 0; i < [self.pieceBezierPathsArray count]; i++) {
        CGRect mCropFrame = [[[self.pieceCoordinateRectArray objectAtIndex:i] objectAtIndex:0] CGRectValue];
        
        CGRect mImageFrame = [[[self.pieceCoordinateRectArray objectAtIndex:i] objectAtIndex:1] CGRectValue];
        
        // 切割图片.
        UIImageView *mPeace = [UIImageView new];
        [mPeace setFrame:mImageFrame];
        [mPeace setTag:i+100];
        [mPeace setUserInteractionEnabled:YES];
        [mPeace setContentMode:UIViewContentModeTopLeft];

        // 修正
        mXAddableVal = ([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeLeft)] integerValue] == PieceTypeOutside)?self.deepnessV:0;
        mYAddableVal = ([[[self.pieceTypeArray objectAtIndex:i] objectForKey:@(PieceSideTypeBottom)] integerValue] == PieceTypeOutside)?self.deepnessH:0;
        mCropFrame.origin.x += mXAddableVal;
        mCropFrame.origin.y += mYAddableVal;
        
        // 添加图片
        [mPeace setImage:[self cropImage:self.originalCatImage withRect:mCropFrame]];
        [self setClippingPath:[self.pieceBezierPathsArray objectAtIndex:i]:mPeace];
        [self.view addSubview:mPeace];
        [mPeace setTransform:CGAffineTransformMakeRotation([[self.pieceRotationArray objectAtIndex:i] floatValue])];
        
        
        // 设置layer 已经边缘线条
        CAShapeLayer *mBorderPathLayer = [CAShapeLayer layer];
        [mBorderPathLayer setPath:[[self.pieceBezierPathsArray objectAtIndex:i] CGPath]];
        [mBorderPathLayer setFillColor:[UIColor clearColor].CGColor];
        [mBorderPathLayer setStrokeColor:[UIColor blackColor].CGColor];
        [mBorderPathLayer setLineWidth:1];
        [mBorderPathLayer setFrame:CGRectZero];
        [[mPeace layer] addSublayer:mBorderPathLayer];

        // 添加手势
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(move:)];
        [panRecognizer setMaximumNumberOfTouches:2];
        [panRecognizer setDelegate:self];
        [mPeace addGestureRecognizer:panRecognizer];

    }
}

- (void)setClippingPath:(UIBezierPath *)clippingPath : (UIImageView *)imgView {
    if (![[imgView layer] mask]){
        [[imgView layer] setMask:[CAShapeLayer layer]];
    }
    [(CAShapeLayer*) [[imgView layer] mask] setPath:[clippingPath CGPath]];
}


- (UIImage *)cropImage:(UIImage*)originalImage withRect:(CGRect)rect {
    return [UIImage imageWithCGImage:CGImageCreateWithImageInRect([originalImage CGImage], rect)];
}


// 修挣图片尺寸
- (UIImage *)imageResize :(UIImage*)img andResizeTo:(CGSize)asize {
    UIImage *newimage;
    if (nil == img) {
        newimage = nil;
    } else{
        CGSize oldsize = img.size;
        CGRect rect;
        if (asize.width/asize.height > oldsize.width/oldsize.height) {
            rect.size.width = asize.height*oldsize.width/oldsize.height;
            rect.size.height = asize.height;
            rect.origin.x = (asize.width - rect.size.width)/2;
            rect.origin.y = 0;
            
        } else{
            rect.size.width = asize.width;
            rect.size.height = asize.width*oldsize.height/oldsize.width;
            rect.origin.x = 0;
            rect.origin.y = (asize.height - rect.size.height)/2;
        }
        UIGraphicsBeginImageContext(asize);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        UIRectFill(CGRectMake(0, 0, asize.width, asize.height));//clear background

        [img drawInRect:rect];
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return newimage;
}


#pragma mark ——— 手势相关
- (void)move:(UIPanGestureRecognizer *)sender {
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.firstX = sender.view.center.x;
        self.firstY = sender.view.center.y;
    }
    UIImageView *mImgView = (UIImageView *)sender.view;
    translatedPoint = CGPointMake(self.firstX+translatedPoint.x, self.firstY+translatedPoint.y);
    [mImgView setCenter:translatedPoint];
    
    // 验证相关
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGRect mImageFrame = [[[self.pieceCoordinateRectArray objectAtIndex:mImgView.tag-100] objectAtIndex:1] CGRectValue];
        CGPoint mimagePoint = CGPointMake(mImageFrame.origin.x +mImageFrame.size.width/2, mImageFrame.origin.y + mImageFrame.size.height/2);
        if ( fabs(mimagePoint.x - mImgView.center.x) <= kVerificationTolerance &&
            fabs(mimagePoint.y - mImgView.center.y) <= kVerificationTolerance) {
            NSLog(@"位置匹配，可以修正");
            [mImgView setCenter:mimagePoint];;
        }else{
            NSLog(@"位置不匹配，%@--- %@",NSStringFromCGPoint(mimagePoint),NSStringFromCGPoint(translatedPoint));
        }
    }
}

@end
