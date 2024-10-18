//
//  ContentView.swift
//  Softkey
//
//  Created by Barry Hall on 2024-10-06.
//

import SwiftUI

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// **********************************************

enum KeyCode: Int {
    case key0 = 0, key1, key2, key3, key4, key5, key6, key7, key8, key9
    
    case plus = 10, minus, times, divide
    
    case dot = 20, enter, clear, back, sign, eex
    
    case fixL = 30, fixR, roll, xy, lastx, sto, rcl, mPlus, mMinus
    
    case y2x = 40, inv, x2, sqrt
    
    case fn0 = 50, sin, cos, tan, log, ln, pi, asin, acos, atan
    
    case tenExp = 60, eExp, e
    
    case fix = 70, sci, eng, percent, currency
    
    case deg = 80, rad, sec, min, hr, yr, mm, cm, m, km
    
    case noop = 90
    
    case sk0 = 100, sk1, sk2, sk3, sk4, sk5, sk6
}


// ****************************************

typealias KeyID = Int

typealias  KeyEvent = KeyCode

protocol KeyPressHandler {
    func keyPress(_ event: KeyEvent )
}

struct KeySpec {
    var width: Double
    var height: Double
    var fontSize:Double = KeySpec.defFontSize
    var keyColor: Color = KeySpec.defKeyColor
    var textColor: Color = KeySpec.defTextColor
    var radius: Double = KeySpec.defRadius
    
    static let defFontSize  = 18.0
    static let defRadius    = 10.0
    static let defKeyColor  = Color(.brown)
    static let defTextColor = Color(.white)
}


struct Key: Identifiable {
    var kc: KeyCode
    var size: Int           // Either 1 or 2, single width keys or double width
    var text: String?
    var fontSize: Double?
    var image: ImageResource?
    
    var id: Int { return self.kc.rawValue }

    init( _ kc: KeyCode, _ label: String? = nil, size: Int = 1, fontSize: Double? = nil, image: ImageResource? = nil ) {
        self.kc = kc
        self.text = label
        self.size = size
        self.image = image
        self.fontSize = fontSize
    }
}

struct SubPadSpec {
    var kc: KeyCode
    var keys: [Key]
    var fontSize: Double?

    static var specList: [KeyCode : SubPadSpec] = [:]
    
    static func define( _ kc: KeyCode, keys: [Key], fontSize: Double? = nil ) {
        SubPadSpec.specList[kc] = SubPadSpec( kc: kc, keys: keys, fontSize: fontSize)
    }
}

struct PadSpec {
    var keySpec: KeySpec
    var cols: Int
    var keys: [Key]
    var fontSize: Double = 18.0
    var caption: String?
}


// ****************************************************
// Sample keyboard data - move to other file

let ksSoftkey = KeySpec( width: 45, height: 30 )
let ksNormal = KeySpec( width: 45, height: 45 )

let psFuntions = PadSpec(
        keySpec: ksSoftkey,
        cols: 6,
        keys: [ Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan"),
                Key(.log, "log"),
                Key(.ln,  "ln"),
                Key(.pi,  "\u{1d70b}")
            ]
    )
    
let psFunc1 = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan")
            ]
    )
    
let psFunc2 = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.log, "log"),
                Key(.ln,  "ln"),
                Key(.pi,  "\u{1d70b}")
            ]
    )
    
let psNumeric = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.key7, "7"), Key(.key8, "8"), Key(.key9, "9"),
                Key(.key4, "4"), Key(.key5, "5"), Key(.key6, "6"),
                Key(.key1, "1"), Key(.key2, "2"), Key(.key3, "3"),
                Key(.key0, "0"), Key(.dot, "."),  Key(.sign, "+/-", fontSize: 15)
              ]
    )

let psEnter = PadSpec(
        keySpec: ksNormal,
        cols: 3,
        keys: [ Key(.enter, "Enter", size: 2, fontSize: 15), Key(.eex, "EE", fontSize: 15)
              ]
    )

let psOperations = PadSpec(
    keySpec: ksNormal,
    cols: 3,
    keys: [ Key(.divide, "÷", fontSize: 24.0), Key(.fixL, ".00\u{2190}", fontSize: 14.0), Key(.y2x, image: .yx),
            Key(.times, "×", fontSize: 24.0),  Key(.lastx, "LASTx", fontSize: 12.0),      Key(.inv, image: .onex),
            Key(.minus, "−", fontSize: 24.0),  Key(.xy, "X\u{21c6}Y", fontSize: 14.0),    Key(.x2,  image: .x2),
            Key(.plus,  "+", fontSize: 24.0),  Key(.roll, "R\u{2193}", fontSize: 14.0),   Key(.sqrt,image: .rx)
          ])

let psClear = PadSpec(
    keySpec: ksNormal,
    cols: 3,
    keys: [ Key(.back, "BACK/UNDO", size: 2, fontSize: 12.0), Key(.clear, "CLx", fontSize: 14.0) ])


func initKeyLayout() {
    SubPadSpec.define( .sin,
                       keys: [
                        Key(.sin, "sin"),
                        Key(.cos, "cos"),
                        Key(.tan, "tan")
                       ],
                       fontSize: 14.0
    )
    
    SubPadSpec.define( .log,
                       keys: [
                        Key(.acos, "acos"),
                        Key(.asin, "asin"),
                        Key(.atan, "atan"),
                        Key(.log,  "log"),
                        Key(.ln,   "ln")
                       ],
                       fontSize: 14.0
    )
}


// ****************************************************

class KeyData : ObservableObject {
    //    Origin of pressed key rect
    //    Rect of outer ZStack
    //    Point of dragged finger
    //    Key struct of pressed key
    //
    var zFrame: CGRect      = CGRect.zero
    var subPad: SubPadSpec? = nil
    var keyOrigin: CGPoint  = CGPoint.zero
    var popFrame: CGRect    = CGRect.zero
    var pressedKey: Key?    = nil

    @Published var dragPt   = CGPoint.zero
    @Published var keyDown  = false
    @Published var hello    = "Hello"
}


let longPressTime = 0.5
let keyInset      = 4.0
let keyHspace     = 10.0
let keyVspace     = 10.0


struct ModalBlock: View {
    @StateObject var keyData: KeyData

    var body: some View {
        if keyData.keyDown {
            // Transparent rectangle to block all key interactions below the popup - opacity 0 passes key presses through
            Rectangle()
                .opacity(0.0001)
        }
    }
}


struct SubPopMenu: View {
    let padSpec: PadSpec
    
    @StateObject var keyData: KeyData
    
    func hitRect( _ r:CGRect ) -> CGRect {
        // Expand a rect to allow hits below the rect so finger does not block key
        r.insetBy(dx: 0.0, dy: -padSpec.keySpec.height*2)
    }

    var body: some View {
        if keyData.keyDown {
            let n = keyData.subPad!.keys.count
            let keyW = padSpec.keySpec.width
            let keyH = padSpec.keySpec.height
            let nkeys = 0..<n
            let subkeys = nkeys.map { keyData.subPad!.keys[$0].text! }
            let w = keyData.popFrame.width
            let keyRect = CGRect( origin: CGPoint.zero, size: CGSize( width: keyW, height: keyH)).insetBy(dx: keyInset/2, dy: keyInset/2)
            let keySet  = nkeys.map { keyRect.offsetBy( dx: padSpec.keySpec.width*Double($0), dy: 0.0) }
            let zOrigin = keyData.zFrame.origin
            
//            Canvas { gc, size in
//                gc.translateBy(x: size.width / 2, y: size.height / 2)
//                let rectangle = Rectangle().path(in: .zero.insetBy(dx: -5, dy: -5))
//                gc.fill(rectangle, with: .color(.green))
//            }
//
            Rectangle()
                .frame( width: w + keyInset, height: keyH + keyInset)
                .foregroundColor(padSpec.keySpec.keyColor)
                .cornerRadius(padSpec.keySpec.radius)
                .background {
                    RoundedRectangle(cornerRadius: padSpec.keySpec.radius)
                        .shadow(radius: padSpec.keySpec.radius)
                }
                .overlay {
                    GeometryReader { geo in
                        let hframe = geo.frame(in: CoordinateSpace.global)
                        
                        HStack( spacing: keyInset ) {
                            ForEach(nkeys, id: \.self) { kn in
                                let r = keySet[kn].offsetBy(dx: hframe.origin.x, dy: hframe.origin.y)
                                let hit = hitRect(r).contains( keyData.dragPt )
                                
                                Rectangle()
                                    .frame( width: r.width, height: r.height )
                                    .cornerRadius(padSpec.keySpec.radius)
                                    .foregroundColor( hit  ?  Color.blue : padSpec.keySpec.keyColor)
                                    .overlay {
                                        Text( subkeys[kn] )
                                            .font(.system(size: keyData.subPad!.fontSize == nil ? padSpec.fontSize : keyData.subPad!.fontSize! ))
                                            .bold()
                                            .foregroundColor(padSpec.keySpec.textColor)
                                    }
                            }
                        }
                        .padding(.leading, keyInset)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
                .position(x: keyData.popFrame.minX - zOrigin.x + w/2, y: keyData.keyOrigin.y - zOrigin.y - keyH/2 - padSpec.keySpec.radius )
        }
    }
}


// ****************************************************

struct KeyView: View {
    let padSpec: PadSpec
    let key: Key

    @StateObject var keyData: KeyData
    
    // For long press gesture - finger is down
    @GestureState private var isPressing = false
    
    private func hitRect( _ r:CGRect ) -> CGRect {
        // Expand a rect to allow hits below the rect so finger does not block key
        r.insetBy(dx: 0.0, dy: -padSpec.keySpec.height*2)
    }
    
    private func computeSubpadGeometry() {
        let n = keyData.subPad!.keys.count
        let keyW = padSpec.keySpec.width
        let keyH = padSpec.keySpec.height
        let nkeys = 0..<n
        let w = padSpec.keySpec.width * Double(n)
        let zOrigin = keyData.zFrame.origin
        
        // Keys leading edge x value relative to zFrame
        let xKey = keyData.keyOrigin.x - zOrigin.x
        
        // Set of all possible x position values for popup
        let xSet = nkeys.map( { xKey - Double($0)*keyW } )
        
        // Filter out values where the popup won't fit in the Z frame
        let xSet2 = xSet.filter( { $0 >= 0 && ($0 + w) <= keyData.zFrame.maxX })
        
        // Sort by distance from mid popup to mid key
        let xSet3 = xSet2.sorted() { x1, x2 in
            let offset = w/2 - xKey - keyW/2
            return abs(x1+offset) < abs(x2+offset)
        }
        
        // Choose the value that optimally centers the popup over the key
        let xPop = xSet3[0]
        
        // Write popup location and size to state object
        keyData.popFrame = CGRect( x: xPop + zOrigin.x, y: keyData.keyOrigin.y - keyH - padSpec.keySpec.radius,
                                   width: w, height: keyH)
    }
    
    var drag: some Gesture {
        DragGesture( minimumDistance: 0, coordinateSpace: .global)
            .onChanged { info in
                // Track finger movements
                keyData.dragPt = info.location
            }
            .onEnded { _ in
                let hit = hitRect(keyData.popFrame).contains(keyData.dragPt)
                
                if hit {
                    let x = Int( (keyData.dragPt.x - keyData.popFrame.minX) / padSpec.keySpec.width )
                    
                    if let pad = keyData.subPad {
                        keyData.hello.append("\nKeypress: \(pad.keys[x].text!)")
                    }
                }
                
                keyData.dragPt = CGPoint.zero
            }
    }
    
    
    var body: some View {

        let keyW = padSpec.keySpec.width * Double(key.size) + Double(key.size - 1) * keyHspace
        
        VStack {
            let txt = key.text ?? "??"
            
            GeometryReader { geometry in
                let vframe = geometry.frame(in: CoordinateSpace.global)
                
                let longPress =
                LongPressGesture( minimumDuration: longPressTime)
                    .sequenced( before: drag )
                    .updating($isPressing) { value, state, transaction in
                        switch value {
                            
                        case .second(true, nil):
                            if let subpad = SubPadSpec.specList[key.kc] {
                                // Start finger tracking
                                keyData.subPad = subpad
                                keyData.keyOrigin = vframe.origin
                                keyData.pressedKey = key
                                
                                // This will pre-select the subkey option above the pressed key
                                keyData.dragPt = CGPoint( x: vframe.midX, y: vframe.minY)
                                
                                computeSubpadGeometry()
                                
                                // Initiate popup menu
                                state = true
                            }
                            
                        default:
                            break
                        }
                    }
                
                Rectangle()
                    .foregroundColor( Color.brown )
                    .frame( width: keyW, height: padSpec.keySpec.height )
                    .cornerRadius( padSpec.keySpec.radius )
                    .simultaneousGesture( longPress )
                    .onChange( of: isPressing) { _, newState in keyData.keyDown = newState }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            keyData.hello.append("\nRegular tap: \(txt)")
                        })
                    .if( key.text != nil ) { view in
                        view.overlay(
                            Text( key.text! )
                                .font(.system(size: key.fontSize != nil ? key.fontSize! : padSpec.fontSize ))
                                .bold()
                                .foregroundColor(Color.white) )
                    }
                    .if ( key.image != nil ) { view in
                        view.overlay(
                            Image(key.image!).renderingMode(.template).foregroundColor(padSpec.keySpec.textColor), alignment: .center)
                    }
            }
            
        }
        .frame( maxWidth: keyW, maxHeight: padSpec.keySpec.height )
        // .border(.blue)
    }
}


struct KeypadView: View {
    let padSpec: PadSpec
    
    @StateObject var keyData: KeyData

    private func partitionKeylist( keys: [Key], rowMax: Int ) -> [[Key]] {
        /// Breakup list of keys into list of rows
        /// Count double or triple width keys as 2 or 3 keys
        /// Do not exceed rowMax keys per row
        var res: [[Key]] = []
        var keylist = keys
        var part: [Key] = []
        var rowCount = 0
        
        while !keylist.isEmpty {
            let key1 = keylist.removeFirst()
            
            if rowCount + key1.size <= rowMax {
                part.append(key1)
                rowCount += key1.size
            }
            else {
                res.append(part)
                part = [key1]
                rowCount = key1.size
            }
        }
        if !part.isEmpty {
            res.append(part)
        }
        
        return res
    }

    var body: some View {
        let keyMatrix = partitionKeylist(keys: padSpec.keys, rowMax: padSpec.cols)
        
        VStack( spacing: keyVspace ) {
            ForEach( 0..<keyMatrix.count, id: \.self) { cx in
                
                HStack( spacing: keyHspace ) {
                    let keys = keyMatrix[cx]
                    
                    ForEach( 0..<keys.count, id: \.self) { kx in
                        let key = keys[kx]
                        
                        KeyView( padSpec: padSpec, key: key, keyData: keyData )
                    }
                }
                // Padding and border around key hstack
                .padding(0)
                //          .border(.red)
                //          .showSizes([.current])
            }
        }
        .border(.green)
        .padding(0)
    }
}


struct KeyStack<Content: View>: View {
    @StateObject var keyData = KeyData()
    
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack {
            Image(systemName: "globe").imageScale(.large).foregroundStyle(.tint)
                    
            Text(keyData.hello)
            Divider()

            ZStack {
                VStack {
                    Spacer()
                    HStack( spacing: 0 ) {
                        KeypadView( padSpec: psFunc1, keyData: keyData )
                        Spacer()
                        KeypadView( padSpec: psFunc2, keyData: keyData )
                    }
                    Spacer()
                    Divider()
                    Spacer()
                    HStack( spacing: 0 ) {
                        VStack {
                            KeypadView( padSpec: psNumeric, keyData: keyData )
                            KeypadView( padSpec: psEnter, keyData: keyData )
                        }
                        Spacer()
                        VStack {
                            KeypadView( padSpec: psOperations, keyData: keyData )
                            KeypadView( padSpec: psClear, keyData: keyData )
                        }
                    }
                    Spacer()
                }
                
                content
                
                ModalBlock( keyData: keyData )
                
                SubPopMenu( padSpec: psFunc1, keyData: keyData)
            }
            .onGeometryChange( for: CGRect.self, of: {proxy in proxy.frame(in: .global)} ) { newValue in
                // Save the popup location so we can determine which key was selected when the drag ends
                keyData.zFrame = newValue
            }
            .border(.brown)
            .padding()
            .alignmentGuide(HorizontalAlignment.leading) { _ in  0 }
        }
    }
}


//#Preview {
//    KeypadView( .functions )
//}
