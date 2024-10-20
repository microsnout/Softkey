//
//  SoftkeyApp.swift
//  Softkey
//
//  Created by Barry Hall on 2024-10-06.
//

import SwiftUI

enum KeyCode: Int {
    case key0 = 0, key1, key2, key3, key4, key5, key6, key7, key8, key9
    
    case plus = 10, minus, times, divide
    
    case dot = 20, enter, clear, back, sign, eex
    
    case fixL = 30, fixR, roll, xy, xz, yz, lastx
    
    case y2x = 40, inv, x2, sqrt
    
    case fn0 = 50, sin, cos, tan, log, ln, pi, asin, acos, atan
    
    case tenExp = 60, eExp, e
    
    case fix = 70, sci, eng, percent, currency
    
    case deg = 80, rad, sec, min, hr, yr, mm, cm, m, km
    
    case noop = 90
    
    case sk0 = 100, sk1, sk2, sk3, sk4, sk5, sk6
}


// ****************************************
// Sample keyboard data

let ksSoftkey = KeySpec( width: 45, height: 30 )
let ksNormal = KeySpec( width: 45, height: 45 )

let psFunctionsL = PadSpec(
        keySpec: ksSoftkey,
        cols: 6,
        keys: [ Key(.sin, "sin"),
                Key(.cos, "cos"),
                Key(.tan, "tan"),
            ]
    )

let psFunctionsR = PadSpec(
        keySpec: ksSoftkey,
        cols: 6,
        keys: [ Key(.log, "log"),
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
                Key(.pi,  "\u{1d70b}", fontSize: 24.0)
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

let psFormatL = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.fix, "fix"),
            Key(.sci, "sci"),
            Key(.percent, "%"),
        ],
    fontSize: 14.0
)

let psFormatR = PadSpec (
    keySpec: ksSoftkey,
    cols: 3,
    keys: [ Key(.currency, "$"),
            Key(.fixL, ".00\u{2190}", fontSize: 12.0),
            Key(.fixR, ".00\u{2192}", fontSize: 12.0),
        ],
    fontSize: 14.0
)

func initKeyLayout() {
    SubPadSpec.define( .sin,
                       keySpec: ksSoftkey,
                       keys: [
                        Key(.sin, "sin"),
                        Key(.cos, "cos"),
                        Key(.tan, "tan")
                       ],
                       fontSize: 14.0
    )
    
    SubPadSpec.define( .log,
                       keySpec: ksSoftkey,
                       keys: [
                        Key(.acos, "acos"),
                        Key(.asin, "asin"),
                        Key(.x2, image: .x2),
                        Key(.log,  "log"),
                        Key(.ln,   "ln")
                       ],
                       fontSize: 14.0,
                       caption: "Functions"
    )
    
    SubPadSpec.define( .xy,
                       keySpec: ksSoftkey,
                       keys: [
                        Key(.xz, "X\u{21c6}Z", fontSize: 14.0),
                        Key(.xy, "X\u{21c6}Y", fontSize: 14.0),
                        Key(.yz, "Y\u{21c6}Z", fontSize: 14.0)
                       ],
                       fontSize: 14.0
    )
}


class SoftkeyModel: ObservableObject, KeyPressHandler {
    
    @Published var display: String = "Hello"
    
    func keyPress(_ event: KeyEvent ) {
        display.append("\nKeypress: \(event)")
    }
}


// ****************************************

struct SoftkeyView: View {
    @StateObject var model = SoftkeyModel()

    var body: some View {
        
        KeyStack() {
            VStack {
                Text(model.display)
                Spacer()
                HStack {
                    KeypadView( padSpec: psFunctionsL, keyPressHandler: model )
                    Spacer()
                    KeypadView( padSpec: psFunctionsR, keyPressHandler: model )
                }
                Divider()
                HStack {
                    VStack( spacing: 15 ) {
                        KeypadView( padSpec: psNumeric, keyPressHandler: model )
                        KeypadView( padSpec: psEnter, keyPressHandler: model )
                    }
                    Spacer()
                    VStack( spacing: 15 ) {
                        KeypadView( padSpec: psOperations, keyPressHandler: model )
                        KeypadView( padSpec: psClear, keyPressHandler: model )
                    }
                }
                Divider()
                HStack {
                    KeypadView( padSpec: psFormatL, keyPressHandler: model )
                    Spacer()
                    KeypadView( padSpec: psFormatR, keyPressHandler: model )
                }
                Spacer()
            }
            .padding( 35 )
        }
    }
}


@main
struct SoftkeyApp: App {
    init() {
        initKeyLayout()
    }
    
    var body: some Scene {
        WindowGroup {
            SoftkeyView()
        }
    }
}
