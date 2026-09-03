// MLIR memrefCopy runtime — required by expand-strided-metadata pass.
// Called as: memrefCopy(elemSize, &srcUnranked, &dstUnranked)
// UnrankedMemRefType = {rank: i64, descriptor: ptr}
// Ranked descriptor = {allocated: ptr, aligned: ptr, offset: i64,
//                      sizes: [rank]i64, strides: [rank]i64}
//
// The data pointer is *aligned*, not allocated.  malloc+alignment padding
// makes those differ; using allocated dropped strided concat into the
// padding and left @forward's detect head at sigmoid(0).

#include <alloca.h>
#include <stdint.h>
#include <string.h>

typedef struct {
  int64_t rank;
  void *descriptor;
} UnrankedMemRefType;

typedef struct {
  void *allocated;
  void *aligned;
  int64_t offset;
} RankedMemRefPrefix;

void memrefCopy(int64_t elemSize, UnrankedMemRefType *srcArg,
                UnrankedMemRefType *dstArg) {
  int64_t rank = srcArg->rank;
  RankedMemRefPrefix *srcHdr = (RankedMemRefPrefix *)srcArg->descriptor;
  RankedMemRefPrefix *dstHdr = (RankedMemRefPrefix *)dstArg->descriptor;
  int64_t *srcSizes = (int64_t *)(srcHdr + 1);
  int64_t *srcStrides = srcSizes + rank;
    int64_t *dstStrides = ((int64_t *)(dstHdr + 1)) + rank;

  for (int64_t r = 0; r < rank; r++)
    if (srcSizes[r] == 0)
      return;

  char *srcBase =
      (char *)srcHdr->aligned + srcHdr->offset * elemSize;
  char *dstBase =
      (char *)dstHdr->aligned + dstHdr->offset * elemSize;

  if (rank == 0) {
    memcpy(dstBase, srcBase, (size_t)elemSize);
    return;
  }

  int64_t totalElems = 1;
  for (int64_t r = 0; r < rank; r++)
    totalElems *= srcSizes[r];

  int64_t *indices = (int64_t *)alloca((size_t)rank * sizeof(int64_t));
  for (int64_t r = 0; r < rank; r++)
    indices[r] = 0;

  for (int64_t i = 0; i < totalElems; i++) {
    int64_t srcOff = 0, dstOff = 0;
    for (int64_t r = 0; r < rank; r++) {
      srcOff += indices[r] * srcStrides[r];
      dstOff += indices[r] * dstStrides[r];
    }
    memcpy(dstBase + dstOff * elemSize, srcBase + srcOff * elemSize,
           (size_t)elemSize);
    for (int64_t r = rank - 1; r >= 0; r--) {
      indices[r]++;
      if (indices[r] < srcSizes[r])
        break;
      indices[r] = 0;
    }
  }
}
