//
//  ContentView.swift
//  Softkey
//
//  Created by Barry Hall on 2024-10-06.
//

import SwiftUI

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
    var image: ImageResource?
    
    var id: Int { return self.kc.rawValue }

    init( _ kc: KeyCode, _ label: String? = nil, size: Int = 1, fontSize: Double? = nil, image: ImageResource? = nil ) {
        self.kc = kc
        self.text = label
        self.size = size
        self.image = image
    }
}

struct SubPadSpec {
    var kc: KeyCode
    var keys: [Key]
    
    static var specList: [KeyCode : SubPadSpec] = [:]
    
    static func define( _ kc: KeyCode, keys: [Key] ) {
        SubPadSpec.specList[kc] = SubPadSpec( kc: kc, keys: keys)
    }
}

struct PadSpec {
    var keySpec: KeySpec
    var cols: Int
    var keys: [Key]
    var fontSize: Double
    var caption: String?
}


// ****************************************************
// Sample keyboard data

let ksSoftkey = KeySpec( width: 50, height: 30 )

let psFuntions = PadSpec(
        keySpec: ksSoftkey,
        cols: 6,
        keys: [ Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan"),
                Key(.log, "log"),
                Key(.ln,  "ln"),
                Key(.pi,  "\u{1d70b}")
            ],
        fontSize: 14.0
    )
    
let psFunc1 = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan")
            ],
        fontSize: 14.0
    )
    
let psFunc2 = PadSpec(
        keySpec: ksSoftkey,
        cols: 3,
        keys: [ Key(.log, "log"),
                Key(.ln,  "ln"),
                Key(.pi,  "\u{1d70b}")
            ],
        fontSize: 14.0
    )
    

func initKeyLayout() {
    SubPadSpec.define( .sin,
               keys: [
                Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan")
               ]
    )
    
    SubPadSpec.define( .log,
                       keys: [
                        Key(.acos, "acos"),
                        Key(.asin, "asin"),
                        Key(.atan, "atan"),
                        Key(.log,  "log")
                       ])
}


// ****************************************************

struct KeypadView: View {
    @Binding var hello: String
    
    let padSpec: PadSpec

    let keyInset      = 4.0
    let longPressTime = 0.5
    
    func hitRect( _ r:CGRect ) -> CGRect {
        // Expand a rect to allow hits below the rect so finger does not block key
        r.insetBy(dx: 0.0, dy: -padSpec.keySpec.height*2)
    }

    // State Vars
    //    Origin of pressed key rect
    //    Rect of outer ZStack
    //    Point of dragged finger
    //    Key struct of pressed key
    //
    @State private var keyOrigin: CGPoint = CGPoint.zero
    @State private var zFrame: CGRect = CGRect.zero
    @State private var dragPt = CGPoint.zero
    @State private var keyPressed: Key? = nil
    @State private var subPad: SubPadSpec? = nil
    @State private var popFrame: CGRect = CGRect.zero
    
    // For long press gesture - finger is down
    @GestureState private var isPressing = false

    
    @ViewBuilder
    private var customModal: some View {
        if isPressing {
            // Transparent rectangle to block all key interactions below the popup - opacity 0 passes key presses through
            Rectangle()
                .opacity(0.0001)
        }
    }


    @ViewBuilder
    private var customPopover: some View {
        if isPressing {
            let n = subPad!.keys.count
            let keyW = padSpec.keySpec.width
            let keyH = padSpec.keySpec.height
            let nkeys = 0..<n
            let subkeys = nkeys.map { subPad!.keys[$0].text! }
//            let subkeys = nkeys.map { String($0 + 1) }
            let w = padSpec.keySpec.width * Double(n)
            let keyRect = CGRect( origin: CGPoint.zero, size: CGSize( width: keyW, height: keyH)).insetBy(dx: keyInset, dy: keyInset)
            let keySet  = nkeys.map { keyRect.offsetBy( dx: padSpec.keySpec.width*Double($0), dy: 0.0) }
            let zOrigin = self.zFrame.origin
            
            // Keys leading edge x value relative to zFrame
            let xKey = keyOrigin.x - zOrigin.x
            
            // Set of all possible x position values for popup
            let xSet = nkeys.map( { xKey - Double($0)*keyW } )
            
            // Filter out values where the popup won't fit in the Z frame
            let xSet2 = xSet.filter( { $0 >= 0 && ($0 + w) <= zFrame.maxX })
            
            // Sort by distance from mid popup to mid key
            let xSet3 = xSet2.sorted() { x1, x2 in
                let offset = w/2 - xKey - keyW/2
                return abs(x1+offset) < abs(x2+offset)
            }
            
            // Choose the value that optimally centers the popup over the key
            let xPop = xSet3[0] + w/2
            
//            Canvas { gc, size in
//                gc.translateBy(x: size.width / 2, y: size.height / 2)
//                let rectangle = Rectangle().path(in: .zero.insetBy(dx: -5, dy: -5))
//                gc.fill(rectangle, with: .color(.green))
//            }
//            
            GeometryReader { geometry in
                Rectangle()
                    .frame( width: w, height: keyH)
                    .foregroundColor(padSpec.keySpec.keyColor)
                    .cornerRadius(padSpec.keySpec.radius)
                    .background {
                        RoundedRectangle(cornerRadius: padSpec.keySpec.radius)
                            .shadow(radius: padSpec.keySpec.radius)
                    }
                    .overlay {
                        GeometryReader { geo in
                            let hframe = geo.frame(in: CoordinateSpace.global)
                            
                            HStack( spacing: keyInset*2 ) {
                                ForEach(nkeys, id: \.self) { kn in
                                    let r = keySet[kn].offsetBy(dx: hframe.origin.x, dy: hframe.origin.y)
                                    let hit = hitRect(r).contains( self.dragPt )
                                    
                                    Rectangle()
                                        .frame( width: r.width, height: r.height )
                                        .cornerRadius(padSpec.keySpec.radius)
                                        .foregroundColor( hit  ?  Color.blue : padSpec.keySpec.keyColor)
                                        .overlay {
                                            Text( subkeys[kn] )
                                                .bold()
                                                .foregroundColor(padSpec.keySpec.textColor)
                                        }
                                }
                            }
                            .padding(.leading, keyInset)
                            .frame(maxHeight: .infinity, alignment: .center)
                            .onGeometryChange( for: CGRect.self, of: {proxy in proxy.frame(in: .global)} ) { newValue in
                                // Save the popup location so we can determine which key was selected when the drag ends
                                popFrame = newValue
                            }
                        }
                    }
                    .position(x: xPop, y: keyOrigin.y - zOrigin.y - keyH/2 - padSpec.keySpec.radius )
            }
        }
    }

    var drag: some Gesture {
        DragGesture( minimumDistance: 0, coordinateSpace: .global)
            .onChanged { info in
                // Track finger movements
                dragPt = info.location
            }
            .onEnded { _ in
                let hit = hitRect(popFrame).contains(self.dragPt)
                
                if hit {
                    let x = Int( (dragPt.x - popFrame.minX) / padSpec.keySpec.width )
                    
                    if let pad = subPad {
                        self.hello.append("\nKeypress: \(pad.keys[x].text!)")
                    }
                }
                
                self.dragPt = CGPoint.zero
            }
    }

    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let zframe = geometry.frame(in: CoordinateSpace.global)
                
                VStack {
                    Spacer()
                    HStack( spacing: 0 ) {
                        let keys = padSpec.keys
                        let range = 0..<keys.count
                        
                        ForEach( range, id: \.self) { kx in
                            let key = padSpec.keys[kx]
                            let txt = key.text ?? "??"
                            
                            VStack {
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
                                                        self.subPad = subpad
                                                        self.keyOrigin = vframe.origin
                                                        self.zFrame = zframe
                                                        self.keyPressed = key
                                                        state = true
                                                        
                                                        // This will pre-select the subkey option above the pressed key
                                                        dragPt = CGPoint( x: vframe.midX, y: vframe.minY)
                                                    }
                                                    
                                                default:
                                                    break
                                                }
                                            }
                                    
                                    Rectangle()
                                        .foregroundColor( Color.brown )
                                        .frame( width: padSpec.keySpec.width, height: padSpec.keySpec.height )
                                        .cornerRadius( padSpec.keySpec.radius )
                                        .overlay(
                                            Text( txt )
                                                .bold()
                                                .foregroundColor(Color.white) )
                                        .simultaneousGesture( longPress )
                                        .simultaneousGesture(
                                            TapGesture().onEnded {
                                                self.hello.append("\nRegular tap: \(txt)")
                                        })
                                }
                                
                            }
                            .frame( maxWidth: padSpec.keySpec.width, maxHeight: padSpec.keySpec.height )
                            // .border(.blue)
                            
                            if kx != keys.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    // Padding and border around key hstack
                    .padding(0)
//                    .border(.red)
//                    .showSizes([.current])
                    
                    Spacer()
                }
                .border(.green)
                .padding(0)
            }

            customModal
            customPopover
        }
        .border(.brown)
        .padding()
        .alignmentGuide(HorizontalAlignment.leading) { _ in  0 }
    }
}


struct KeyFrame: View {
    @State private var hello: String = "Hello"

    var body: some View {
        VStack {
            Image(systemName: "globe").imageScale(.large).foregroundStyle(.tint)
                    
            Text(self.hello)
            Divider()

            HStack( spacing: 0 ) {
                KeypadView( hello: $hello, padSpec: psFunc1 )
                KeypadView( hello: $hello, padSpec: psFunc2 )
            }
        }
    }
}


//#Preview {
//    KeypadView( .functions )
//}
