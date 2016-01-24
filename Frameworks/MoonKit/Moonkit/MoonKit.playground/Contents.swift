import Foundation
import MoonKit

let x =  324.606743623764
let y =  21.0
let dx =  -144.9763520779608
let dy = 223.4146814806358

let m = dy/dx

let pointsPerTick = 0.1605579419
let 𝝙ticks: Double = 1526

// yʹ = m * (xʹ - x) + y

// (xʹ - x)² + (yʹ - y)² = (𝝙ticks * pointsPerTick)²
var c = pow(𝝙ticks * pointsPerTick, 2)

// (xʹ - x)² + (m * (xʹ - x) + y - y)² = c

// xʹ² - 2xʹx + x² + m²xʹ² - 2m²xʹx + m²x² = c
//              --                    ----
// merge known into c
c -= pow(x, 2)
c -= pow(m, 2) * pow(x, 2)

// xʹ² - 2xʹx + m²xʹ² - 2m²xʹx = c
// combine terms
// (m² + 1)xʹ² - 2xʹx - 2m²xʹx = c
// (m² + 1)xʹ² - 2xʹx(1 + m²) = c
let a = pow(m, 2) + 1

// axʹ² - 2xʹx(1 + m²) = c
let b = (pow(m, 2) + 1) * x * 2

// axʹ² - bxʹ - c = 0

let xʹ1 = (-b + sqrt(pow(b, 2) - 4 * a * c)) / (2 * a)
let xʹ2 = (-b - sqrt(pow(b, 2) - 4 * a * c)) / (2 * a)

// yʹ = m * (xʹ - x) + y
let yʹ1 = m * (xʹ1 - x) + y

// (xʹ - x)² + (yʹ - y)² = (𝝙ticks * pointsPerTick)²
sqrt(pow(xʹ1 - x, 2) + pow(yʹ1 - y, 2))

1526.0 / 3007 * (426 - 21) + y

1526.0 / 3007 * (61.7975933814904 - x) + x

sqrt(201.0 * 201 + 211 * 211)
1411 * pointsPerTick