import    Foundation

struct   Person   {
var   name:   String
var age:Int
}

extension    Person   {
func    getInfo()   ->   String   {
return   "\(name) is \(age) years old"
}
}

func    calculate(  a:Int,b:Int,c:Int  )->Int{
let result=a+b+c
return     result
}

func main(){
let numbers=[1,2,3,4,5]
var doubled=[Int]()

for   num   in   numbers{
doubled.append(num*2)
}

let person=Person(name:"Alice",age:30)
let info=person.getInfo()

if   true{
print(  "This has bad spacing"  )
let x=1+2+3
let y=x*2
print(info)
}
}
