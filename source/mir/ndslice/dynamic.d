/++
$(SCRIPT inhibitQuickIndex = 1;)

This is a submodule of $(MREF mir, ndslice).

Operators only change strides and lengths of a slice.
The range of a slice remains unmodified.
All operators return slice of the same type as the type of the argument.

$(BOOKTABLE $(H2 Transpose operators),

$(TR $(TH Function Name) $(TH Description))
$(T2 transposed, Permutes dimensions. $(BR)
    `iota(3, 4, 5, 6, 7).transposed!(4, 0, 1).shape` returns `[7, 3, 4, 5, 6]`.)
$(T2 swapped, Swaps dimensions $(BR)
    `iota(3, 4, 5).swapped!(1, 2).shape` returns `[3, 5, 4]`.)
$(T2 everted, Reverses the order of dimensions $(BR)
    `iota(3, 4, 5).everted.shape` returns `[5, 4, 3]`.)
)
See also $(SUBREF topology, evertPack).

$(BOOKTABLE $(H2 Iteration operators),

$(TR $(TH Function Name) $(TH Description))
$(T2 strided, Multiplies the stride of a selected dimension by a factor.$(BR)
    `iota(13, 40).strided!(0, 1)(2, 5).shape` equals to `[7, 8]`.)
$(T2 reversed, Reverses the direction of iteration for selected dimensions. $(BR)
    `slice.reversed!0` returns the slice with reversed direction of iteration for top level dimension.)
$(T2 allReversed, Reverses the direction of iteration for all dimensions. $(BR)
    `iota(4, 5).allReversed` equals to `20.iota.retro.sliced(4, 5)`.)
)

$(BOOKTABLE $(H2 Other operators),
$(TR $(TH Function Name) $(TH Description))

$(T2 rotated, Rotates two selected dimensions by `k*90` degrees. $(BR)
    `iota(2, 3).rotated` equals to `[[2, 5], [1, 4], [0, 3]]`.)
$(T2 dropToHypercube, Returns maximal multidimensional cube of a slice.)

)

$(H2 Bifacial operators)

Some operators are bifacial,
i.e. they have two versions: one with template parameters, and another one
with function parameters. Versions with template parameters are preferable
because they allow compile time checks and can be optimized better.

$(BOOKTABLE ,

$(TR $(TH Function Name) $(TH Variadic) $(TH Template) $(TH Function))
$(T4 swapped, No, `slice.swapped!(2, 3)`, `slice.swapped(2, 3)`)
$(T4 rotated, No, `slice.rotated!(2, 3)(-1)`, `slice.rotated(2, 3, -1)`)
$(T4 strided, Yes/No, `slice.strided!(1, 2)(20, 40)`, `slice.strided(1, 20).strided(2, 40)`)
$(T4 transposed, Yes, `slice.transposed!(1, 4, 3)`, `slice.transposed(1, 4, 3)`)
$(T4 reversed, Yes, `slice.reversed!(0, 2)`, `slice.reversed(0, 2)`)
)

Bifacial interface of $(LREF drop), $(LREF dropBack)
$(LREF dropExactly), and $(LREF dropBackExactly)
is identical to that of $(LREF strided).

Bifacial interface of $(LREF dropOne) and $(LREF dropBackOne)
is identical to that of $(LREF reversed).

License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).

Copyright: Copyright © 2016, Ilya Yaroshenko

Authors:   Ilya Yaroshenko

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))
+/
module mir.ndslice.dynamic;


import std.traits;
import std.meta;

import mir.internal.utility;
import mir.ndslice.internal;
import mir.ndslice.slice;
import mir.utility;

@fastmath:

private enum _swappedCode = q{
    with (slice)
    {
        auto tl = _lengths[dimensionA];
        auto ts = _strides[dimensionA];
        _lengths[dimensionA] = _lengths[dimensionB];
        _strides[dimensionA] = _strides[dimensionB];
        _lengths[dimensionB] = tl;
        _strides[dimensionB] = ts;
    }
    return slice;
};

/++
Swaps two dimensions.

Params:
    slice = input slice
    dimensionA = first dimension
    dimensionB = second dimension
Returns:
    n-dimensional slice of the same type
See_also: $(LREF everted), $(LREF transposed)
+/
template swapped(size_t dimensionA, size_t dimensionB)
{
    ///
    @fastmath Slice!(kind, packs, Iterator) swapped(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice)
        if (kind == Universal || kind == Canonical)
    {
        {
            enum i = 0;
            alias dimension = dimensionA;
            mixin DimensionCTError;
        }
        {
            enum i = 1;
            alias dimension = dimensionB;
            mixin DimensionCTError;
        }
        mixin (_swappedCode);
    }
}

/// ditto
Slice!(kind, packs, Iterator) swapped(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice, size_t dimensionA, size_t dimensionB)
    if (kind == Universal || kind == Canonical)
in{
    {
        alias dimension = dimensionA;
        mixin (DimensionRTError);
    }
    {
        alias dimension = dimensionB;
        mixin (DimensionRTError);
    }
}
body
{
    mixin (_swappedCode);
}

/// ditto
Slice!(Universal, [2], Iterator) swapped(Iterator)(Slice!(Universal, [2], Iterator) slice)
body
{
    return slice.swapped!(0, 1);
}

/// Template
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, canonical, universal;

    assert(iota(3, 4, 5, 6)
        .canonical
        .swapped!(2, 1)
        .shape == cast(size_t[4])[3, 5, 4, 6]);

    assert(iota(3, 4, 5, 6)
        .universal
        .swapped!(3, 1)
        .shape == cast(size_t[4])[3, 6, 5, 4]);
}

/// Function
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, canonical, universal;

    assert(iota(3, 4, 5, 6)
        .canonical
        .swapped(1, 2)
        .shape == cast(size_t[4])[3, 5, 4, 6]);

    assert(iota(3, 4, 5, 6)
        .universal
        .swapped(1, 3)
        .shape == cast(size_t[4])[3, 6, 5, 4]);
}

/// 2D
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, universal;
    assert(iota(3, 4)
        .universal
        .swapped
        .shape == cast(size_t[2])[4, 3]);
}

private enum _rotatedCode = q{
    k &= 0b11;
    if (k == 0)
        return slice;
    if (k == 2)
        return slice.allReversed;
    static if (__traits(compiles, { enum _enum = dimensionA + dimensionB; }))
    {
        slice = slice.swapped!(dimensionA, dimensionB);
        if (k == 1)
            return slice.reversed!dimensionA;
        else
            return slice.reversed!dimensionB;
    }
    else
    {
        slice = slice.swapped (dimensionA, dimensionB);
        if (k == 1)
            return slice.reversed(dimensionA);
        else
            return slice.reversed(dimensionB);
    }
};

/++
Rotates two selected dimensions by `k*90` degrees.
The order of dimensions is important.
If the slice has two dimensions, the default direction is counterclockwise.

Params:
    slice = input slice
    dimensionA = first dimension
    dimensionB = second dimension
    k = rotation counter, can be negative
Returns:
    n-dimensional slice of the same type
+/
template rotated(size_t dimensionA, size_t dimensionB)
{
    ///
    @fastmath Slice!(kind, packs, Iterator) rotated(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice, sizediff_t k = 1)
        if (kind == Universal || kind == Canonical)
    {
        {
            enum i = 0;
            alias dimension = dimensionA;
            mixin DimensionCTError;
        }
        {
            enum i = 1;
            alias dimension = dimensionB;
            mixin DimensionCTError;
        }
        mixin (_rotatedCode);
    }
}

/// ditto
Slice!(kind, packs, Iterator) rotated(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice,
    size_t dimensionA, size_t dimensionB, sizediff_t k = 1)
    if (kind == Universal || kind == Canonical)
in{
    {
        alias dimension = dimensionA;
        mixin (DimensionRTError);
    }
    {
        alias dimension = dimensionB;
        mixin (DimensionRTError);
    }
}
body
{
    mixin (_rotatedCode);
}

/// ditto
Slice!(Universal, [2], Iterator) rotated(Iterator)(Slice!(Universal, [2], Iterator) slice, sizediff_t k = 1)
body
{
    return slice.rotated!(0, 1)(k);
}

///
@safe pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, universal;
    auto slice = iota(2, 3).universal;

    auto a = [[0, 1, 2],
              [3, 4, 5]];

    auto b = [[2, 5],
              [1, 4],
              [0, 3]];

    auto c = [[5, 4, 3],
              [2, 1, 0]];

    auto d = [[3, 0],
              [4, 1],
              [5, 2]];

    assert(slice.rotated       ( 4) == a);
    assert(slice.rotated!(0, 1)(-4) == a);
    assert(slice.rotated (1, 0,  8) == a);

    assert(slice.rotated            == b);
    assert(slice.rotated!(0, 1)(-3) == b);
    assert(slice.rotated (1, 0,  3) == b);

    assert(slice.rotated       ( 6) == c);
    assert(slice.rotated!(0, 1)( 2) == c);
    assert(slice.rotated (0, 1, -2) == c);

    assert(slice.rotated       ( 7) == d);
    assert(slice.rotated!(0, 1)( 3) == d);
    assert(slice.rotated (1, 0,   ) == d);
}

/++
Reverses the order of dimensions.

Params:
    slice = input slice
Returns:
    n-dimensional slice of the same type
See_also: $(LREF swapped), $(LREF transposed)
+/
Slice!(kind, packs, Iterator) everted(size_t[] packs, SliceKind kind, Iterator)(Slice!(kind, packs, Iterator) slice)
    if (kind == Universal || kind == Canonical && packs.length > 1)
{
    with(slice) foreach (i; Iota!(packs[0] / 2))
    {
        swap(_lengths[i], _lengths[packs[0] - i - 1]);
        swap(_strides[i], _strides[packs[0] - i - 1]);
    }
    return slice;
}

///
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, universal;
    assert(iota(3, 4, 5)
        .universal
        .everted
        .shape == cast(size_t[3])[5, 4, 3]);
}

private enum _transposedCode = q{
    size_t[typeof(return).N] lengths_;
    ptrdiff_t[max(typeof(return).S, size_t(1))] strides_;
    with(slice) foreach (i; Iota!(packs[0]))
    {
        lengths_[i] = _lengths[perm[i]];
        static if (i < typeof(return).S)
            strides_[i] = _strides[perm[i]];
    }
    with(slice) foreach (i; Iota!(packs[0], slice.N))
    {
        lengths_[i] = _lengths[i];
        static if (i < typeof(return).S)
            strides_[i] = _strides[i];
    }
    return typeof(return)(lengths_, strides_[0 .. typeof(return).S], slice._iterator);
};

private size_t[N] completeTranspose(size_t N)(size_t[] dimensions)
{
    assert(dimensions.length <= N);
    size_t[N] ctr;
    uint[N] mask;
    foreach (i, ref dimension; dimensions)
    {
        mask[dimension] = true;
        ctr[i] = dimension;
    }
    size_t j = dimensions.length;
    foreach (i, e; mask)
        if (e == false)
            ctr[j++] = i;
    return ctr;
}

/++
N-dimensional transpose operator.
Brings selected dimensions to the first position.
Params:
    slice = input slice
    Dimensions = indexes of dimensions to be brought to the first position
    dimensions = indexes of dimensions to be brought to the first position
Returns:
    n-dimensional slice of the same type
See_also: $(LREF swapped), $(LREF everted)
+/
template transposed(Dimensions...)
    if (Dimensions.length)
{
    static if (!allSatisfy!(isSize_t, Dimensions))
        alias transposed = .transposed!(staticMap!(toSize_t, Dimensions));
    else
    ///
    @fastmath Slice!(kind, packs, Iterator) transposed(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice)
        if (kind == Universal || kind == Canonical)
    {
        mixin DimensionsCountCTError;
        foreach (i, dimension; Dimensions)
            mixin DimensionCTError;
        static assert(isValidPartialPermutation!(packs[0])([Dimensions]),
            "Failed to complete permutation of dimensions " ~ Dimensions.stringof
            ~ tailErrorMessage!());
        enum perm = completeTranspose!(packs[0])([Dimensions]);
        static assert(perm.isPermutation, __PRETTY_FUNCTION__ ~ ": internal error.");
        mixin (_transposedCode);
    }
}

///ditto
Slice!(kind, packs, Iterator) transposed(SliceKind kind, size_t[] packs, Iterator, size_t M)(Slice!(kind, packs, Iterator) slice, size_t[M] dimensions...)
    if (kind == Universal || kind == Canonical)
in
{
    mixin (DimensionsCountRTError);
    foreach (dimension; dimensions)
        mixin (DimensionRTError);
}
body
{
    assert(dimensions.isValidPartialPermutation!(packs[0]),
        "Failed to complete permutation of dimensions."
        ~ tailErrorMessage!());
    immutable perm = completeTranspose!(packs[0])(dimensions);
    assert(perm.isPermutation, __PRETTY_FUNCTION__ ~ ": internal error.");
    mixin (_transposedCode);
}

///ditto
Slice!(Universal, [2], Iterator) transposed(Iterator)(Slice!(Universal, [2], Iterator) slice)
{
    return .transposed!(1, 0)(slice);
}

/// Template
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, canonical, universal;

    assert(iota(3, 4, 5, 6, 7)
        .canonical
        .transposed!(3, 1, 0)
        .shape == cast(size_t[5])[6, 4, 3, 5, 7]);

    assert(iota(3, 4, 5, 6, 7)
        .universal
        .transposed!(4, 1, 0)
        .shape == cast(size_t[5])[7, 4, 3, 5, 6]);
}

/// Function
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, canonical, universal;

    assert(iota(3, 4, 5, 6, 7)
        .canonical
        .transposed(3, 1, 0)
        .shape == cast(size_t[5])[6, 4, 3, 5, 7]);

    assert(iota(3, 4, 5, 6, 7)
        .universal
        .transposed(4, 1, 0)
        .shape == cast(size_t[5])[7, 4, 3, 5, 6]);
}

/// Single-argument function
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, canonical, universal;

    assert(iota(3, 4, 5, 6, 7)
        .canonical
        .transposed(3)
        .shape == cast(size_t[5])[6, 3, 4, 5, 7]);

    assert(iota(3, 4, 5, 6, 7)
        .universal
        .transposed(4)
        .shape == cast(size_t[5])[7, 3, 4, 5, 6]);
}

/// _2-dimensional transpose
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, universal;
    assert(iota(3, 4)
        .universal
        .transposed
        .shape == cast(size_t[2])[4, 3]);
}

private enum _reversedCode = q{
    with (slice)
    {
        if (_lengths[dimension])
            _iterator += _strides[dimension] * (_lengths[dimension] - 1);
        _strides[dimension] = -_strides[dimension];
    }
};

/++
Reverses the direction of iteration for all dimensions.
Params:
    slice = input slice
Returns:
    n-dimensional slice of the same type
+/
Slice!(kind, packs, Iterator) allReversed(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice)
    @trusted
    if (kind == Universal || kind == Canonical && packs.length > 1)
{
    foreach (dimension; Iota!(packs[0]))
    {
        mixin (_reversedCode);
    }
    return slice;
}

///
@safe @nogc pure nothrow
unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology : iota, retro, universal;
    assert(iota(4, 5).universal.allReversed == iota(4, 5).retro);
}

/++
Reverses the direction of iteration for selected dimensions.

Params:
    slice = input slice
    Dimensions = indexes of dimensions to reverse order of iteration
    dimensions = indexes of dimensions to reverse order of iteration
Returns:
    n-dimensional slice of the same type
+/
template reversed(Dimensions...)
    if (Dimensions.length)
{
    static if (!allSatisfy!(isSize_t, Dimensions))
        alias reversed = .reversed!(staticMap!(toSize_t, Dimensions));
    else
    ///
    @fastmath Slice!(kind, packs, Iterator)
        reversed(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice)
        @trusted
        if (kind == Universal || kind == Canonical)
    {
        foreach (i, dimension; Dimensions)
        {
            mixin DimensionCTError;
            mixin (_reversedCode);
        }
        return slice;
    }
}

///ditto
Slice!(kind, packs, Iterator) reversed(SliceKind kind, size_t[] packs, Iterator, size_t M)(Slice!(kind, packs, Iterator) slice, size_t[M] dimensions...)
    @trusted
    if (kind == Universal || kind == Canonical)
in
{
    foreach (dimension; dimensions)
        mixin (DimensionRTError);
}
body
{
    foreach (i; Iota!(0, M))
    {
        auto dimension = dimensions[i];
        mixin (_reversedCode);
    }
    return slice;
}

///
@safe pure nothrow unittest
{
    import mir.ndslice.topology: iota, universal;
    auto slice = iota([2, 2], 1).universal;
    assert(slice                    == [[1, 2], [3, 4]]);

    // Template
    assert(slice.reversed! 0        == [[3, 4], [1, 2]]);
    assert(slice.reversed! 1        == [[2, 1], [4, 3]]);
    assert(slice.reversed!(0, 1)    == [[4, 3], [2, 1]]);
    assert(slice.reversed!(1, 0)    == [[4, 3], [2, 1]]);
    assert(slice.reversed!(1, 1)    == [[1, 2], [3, 4]]);
    assert(slice.reversed!(0, 0, 0) == [[3, 4], [1, 2]]);

    // Function
    assert(slice.reversed (0)       == [[3, 4], [1, 2]]);
    assert(slice.reversed (1)       == [[2, 1], [4, 3]]);
    assert(slice.reversed (0, 1)    == [[4, 3], [2, 1]]);
    assert(slice.reversed (1, 0)    == [[4, 3], [2, 1]]);
    assert(slice.reversed (1, 1)    == [[1, 2], [3, 4]]);
    assert(slice.reversed (0, 0, 0) == [[3, 4], [1, 2]]);
}

///
@safe pure nothrow unittest
{
    import mir.ndslice.topology: iota, canonical;
    auto slice = iota([2, 2], 1).canonical;
    assert(slice                    == [[1, 2], [3, 4]]);

    // Template
    assert(slice.reversed! 0        == [[3, 4], [1, 2]]);
    assert(slice.reversed!(0, 0, 0) == [[3, 4], [1, 2]]);

    // Function
    assert(slice.reversed (0)       == [[3, 4], [1, 2]]);
    assert(slice.reversed (0, 0, 0) == [[3, 4], [1, 2]]);
}

@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology;
    import std.algorithm.comparison : equal;
    import std.range : chain;
    auto i0 = iota([4], 0); auto r0 = i0.retro;
    auto i1 = iota([4], 4); auto r1 = i1.retro;
    auto i2 = iota([4], 8); auto r2 = i2.retro;
    auto slice = iota(3, 4).universal;
    assert(slice                   .flattened.equal(chain(i0, i1, i2)));
    // Template
    assert(slice.reversed!(0)      .flattened.equal(chain(i2, i1, i0)));
    assert(slice.reversed!(1)      .flattened.equal(chain(r0, r1, r2)));
    assert(slice.reversed!(0, 1)   .flattened.equal(chain(r2, r1, r0)));
    assert(slice.reversed!(1, 0)   .flattened.equal(chain(r2, r1, r0)));
    assert(slice.reversed!(1, 1)   .flattened.equal(chain(i0, i1, i2)));
    assert(slice.reversed!(0, 0, 0).flattened.equal(chain(i2, i1, i0)));
    // Function
    assert(slice.reversed (0)      .flattened.equal(chain(i2, i1, i0)));
    assert(slice.reversed (1)      .flattened.equal(chain(r0, r1, r2)));
    assert(slice.reversed (0, 1)   .flattened.equal(chain(r2, r1, r0)));
    assert(slice.reversed (1, 0)   .flattened.equal(chain(r2, r1, r0)));
    assert(slice.reversed (1, 1)   .flattened.equal(chain(i0, i1, i2)));
    assert(slice.reversed (0, 0, 0).flattened.equal(chain(i2, i1, i0)));
}

private enum _stridedCode = q{
    assert(factor > 0, "factor must be positive"
        ~ tailErrorMessage!());
    immutable rem = slice._lengths[dimension] % factor;
    slice._lengths[dimension] /= factor;
    if (slice._lengths[dimension]) //do not remove `if (...)`
        slice._strides[dimension] *= factor;
    if (rem)
        slice._lengths[dimension]++;
};

/++
Multiplies the stride of the selected dimension by a factor.

Params:
    Dimensions = indexes of dimensions to be strided
    dimension = indexe of a dimension to be strided
    factor = step extension factors
Returns:
    n-dimensional slice of the same type
+/
template strided(Dimensions...)
    if (Dimensions.length)
{
    static if (!allSatisfy!(isSize_t, Dimensions))
        alias strided = .strided!(staticMap!(toSize_t, Dimensions));
    else
    /++
    Params:
        slice = input slice
        factors = list of step extension factors
    +/
    @fastmath Slice!(kind, packs, Iterator) strided(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice, Repeat!(Dimensions.length, ptrdiff_t) factors)
        if (kind == Universal || kind == Canonical)
    {
        foreach (i, dimension; Dimensions)
        {
            mixin DimensionCTError;
            immutable factor = factors[i];
            mixin (_stridedCode);
        }
        return slice;
    }
}

///ditto
Slice!(kind, packs, Iterator) strided(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice, size_t dimension, ptrdiff_t factor)
in
{
    mixin (DimensionRTError);
}
body
{
    mixin (_stridedCode);
    return slice;
}

///
pure nothrow unittest
{
    import mir.ndslice.topology: iota, universal;
    auto slice = iota(3, 4).universal;

    assert(slice
        == [[0,1,2,3], [4,5,6,7], [8,9,10,11]]);

    // Template
    assert(slice.strided!0(2)
        == [[0,1,2,3],            [8,9,10,11]]);

    assert(slice.strided!1(3)
        == [[0,    3], [4,    7], [8,     11]]);

    assert(slice.strided!(0, 1)(2, 3)
        == [[0,    3],            [8,     11]]);

    // Function
    assert(slice.strided(0, 2)
        == [[0,1,2,3],            [8,9,10,11]]);

    assert(slice.strided(1, 3)
        == [[0,    3], [4,    7], [8,     11]]);

    assert(slice.strided(0, 2).strided(1, 3)
        == [[0,    3],            [8,     11]]);
}

///
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.topology : iota, universal;
    static assert(iota(13, 40).universal.strided!(0, 1)(2, 5).shape == [7, 8]);
    static assert(iota(93).universal.strided!(0, 0)(7, 3).shape == [5]);
}

///
pure nothrow unittest
{
    import mir.ndslice.topology: iota, canonical;
    auto slice = iota(3, 4).canonical;

    assert(slice
        == [[0,1,2,3], [4,5,6,7], [8,9,10,11]]);

    // Template
    assert(slice.strided!0(2)
        == [[0,1,2,3],            [8,9,10,11]]);

    // Function
    assert(slice.strided(0, 2)
        == [[0,1,2,3],            [8,9,10,11]]);
}

@safe @nogc pure nothrow unittest
{
    import mir.ndslice.slice;
    import mir.ndslice.topology;
    import std.algorithm.comparison : equal;
    import std.range : chain;
    auto i0 = iota([4], 0); auto s0 = stride(i0, 3);
    auto i1 = iota([4], 4); auto s1 = stride(i1, 3);
    auto i2 = iota([4], 8); auto s2 = stride(i2, 3);
    auto slice = iota(3, 4).universal;
    assert(slice              .flattened.equal(chain(i0, i1, i2)));
    // Template
    assert(slice.strided!0(2) .flattened.equal(chain(i0, i2)));
    assert(slice.strided!1(3) .flattened.equal(chain(s0, s1, s2)));
    assert(slice.strided!(0, 1)(2, 3).flattened.equal(chain(s0, s2)));
    // Function
    assert(slice.strided(0, 2).flattened.equal(chain(i0, i2)));
    assert(slice.strided(1, 3).flattened.equal(chain(s0, s1, s2)));
    assert(slice.strided(0, 2).strided(1, 3).flattened.equal(chain(s0, s2)));
}

/++
Returns maximal multidimensional cube.

Params:
    slice = input slice
Returns:
    n-dimensional slice of the same type
+/
Slice!(kind, packs, Iterator) dropToHypercube(SliceKind kind, size_t[] packs, Iterator)(Slice!(kind, packs, Iterator) slice)
    if (kind == Canonical || kind == Universal)
body
{
    size_t length = slice._lengths[0];
    foreach (i; Iota!(1, packs[0]))
        if (length > slice._lengths[i])
            length = slice._lengths[i];
    foreach (i; Iota!(packs[0]))
        slice._lengths[i] = length;
    return slice;
}

///
@safe @nogc pure nothrow unittest
{
    import mir.ndslice.topology : iota, canonical, universal;

    assert(iota(5, 3, 6, 7)
        .canonical
        .dropToHypercube
        .shape == cast(size_t[4])[3, 3, 3, 3]);

    assert(iota(5, 3, 6, 7)
        .universal
        .dropToHypercube
        .shape == cast(size_t[4])[3, 3, 3, 3]);
}
