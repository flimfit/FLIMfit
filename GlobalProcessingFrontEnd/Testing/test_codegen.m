%#codegen
function b= test_codegen(a)
assert(isa(a,'double'));
b=pinv(a);
end