import Foundation

infix operator ⊻ { associativity none precedence 130 }
infix operator ⊻= { associativity right precedence 90 assignment }
infix operator ∈ { associativity none precedence 130 }
infix operator ∉ { associativity none precedence 130 }
infix operator ∋ { associativity none precedence 130 }
infix operator ∌ { associativity none precedence 130 }
infix operator ∖ { associativity left precedence 130 }
infix operator ∪ { associativity left precedence 130 }
infix operator ∩ { associativity left precedence 130 }
infix operator ∆ { associativity none precedence 130 }
infix operator ∖= { associativity right precedence 90 assignment }
infix operator ∪= { associativity right precedence 90 assignment }
infix operator ∩= 	{ associativity right precedence 90 assignment }
infix operator ∆=	{ associativity right precedence 90 assignment }
infix operator ⊂ { associativity none precedence 130 }
infix operator ⊄ { associativity none precedence 130 }
infix operator ⊆ { associativity none precedence 130 }
infix operator ⊇ { associativity none precedence 130 }
infix operator ⊈ { associativity none precedence 130 }
infix operator ⊉ { associativity none precedence 130 }
infix operator ⊃ { associativity none precedence 130 }
infix operator ⊅ { associativity none precedence 130 }
infix operator ➤ { associativity none precedence 130 }
infix operator ➤| { associativity none precedence 130 }
infix operator >>> { associativity left }
infix operator >>= {}
infix operator ?>> {associativity left}
infix operator >?> {associativity left}
infix operator ∘ {}
infix operator ** { associativity left precedence 170 }
infix operator ⥣ { associativity none precedence 130 }
prefix operator ¶ {}
infix operator ¶| {}
infix operator ⚭ { associativity none precedence 130 }
infix operator !⚭ { associativity none precedence 130 }
infix operator !~= { associativity none precedence 130 }
infix operator ⟷ { associativity none precedence 170 }

postfix operator ~ {}
prefix operator * {}