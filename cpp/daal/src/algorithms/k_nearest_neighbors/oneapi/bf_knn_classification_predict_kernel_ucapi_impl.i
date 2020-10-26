/* file: bf_knn_classification_predict_kernel_ucapi_impl.i */
/*******************************************************************************
* Copyright 2014-2020 Intel Corporation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

#ifndef __BF_KNN_CLASSIFICATION_PREDICT_KERNEL_UCAPI_IMPL_I__
#define __BF_KNN_CLASSIFICATION_PREDICT_KERNEL_UCAPI_IMPL_I__

#include "algorithms/engines/engine.h"
#include "src/sycl/reducer.h"
#include "src/sycl/select_indexed.h"
#include "src/sycl/sorter.h"
#include "src/services/service_data_utils.h"
#include "services/daal_defines.h"

#include "src/algorithms/k_nearest_neighbors/oneapi/bf_knn_classification_predict_kernel_ucapi.h"
#include "src/algorithms/k_nearest_neighbors/oneapi/bf_knn_classification_model_ucapi_impl.h"

#include "src/sycl/blas_gpu.h"
#include "src/algorithms/k_nearest_neighbors/oneapi/cl_kernels/bf_knn_cl_kernels.cl"

#include "src/externals/service_ittnotify.h"

constexpr size_t maxInt32AsSizeT     = static_cast<size_t>(daal::services::internal::MaxVal<int32_t>::get());
constexpr uint32_t maxInt32AsUint32T = static_cast<uint32_t>(daal::services::internal::MaxVal<int32_t>::get());

namespace daal
{
namespace algorithms
{
namespace bf_knn_classification
{
namespace prediction
{
namespace internal
{
using namespace daal::services::internal::sycl;
using namespace services;
using sort::RadixSort;
using selection::QuickSelectIndexed;
using selection::SelectIndexed;
using selection::SelectIndexedFactory;

class Range
{
public:
    static Range createFromBlock(uint32_t blockIndex, uint32_t maxBlockSize, uint32_t sumOfBlocksSize)
    {
        // TODO: check that arguments are correct

        const uint32_t startIndex = blockIndex * maxBlockSize;
        const uint32_t endIndex   = startIndex + maxBlockSize;
        return Range { startIndex, endIndex > sumOfBlocksSize ? sumOfBlocksSize : endIndex };
    }

    uint32_t startIndex;
    uint32_t endIndex;
    uint32_t count;

private:
    Range(uint32_t startIndex, uint32_t endIndex) : startIndex(startIndex), endIndex(endIndex), count(endIndex - startIndex) {}
};

template <typename algorithmFpType>
services::Status KNNClassificationPredictKernelUCAPI<algorithmFpType>::compute(const NumericTable * x, const classifier::Model * m, NumericTable * y,
                                                                               const daal::algorithms::Parameter * par)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute);

    services::Status st;

    auto & context = services::internal::getDefaultContext();

    const Model * model = static_cast<const Model *>(m);

    NumericTable * ntData = const_cast<NumericTable *>(x);
    NumericTable * points = const_cast<NumericTable *>(model->impl()->getData().get());
    NumericTable * labels = const_cast<NumericTable *>(model->impl()->getLabels().get());

    const Parameter * const parameter = static_cast<const Parameter *>(par);
    const size_t kAsSizeT             = parameter->k;
    DAAL_CHECK(kAsSizeT <= maxInt32AsSizeT, services::ErrorIncorrectParameter);
    const uint32_t k = static_cast<uint32_t>(kAsSizeT);

    const size_t nQueryRowsSizeT     = ntData->getNumberOfRows();
    const size_t nQueryFeaturesSizeT = ntData->getNumberOfColumns();
    const size_t nLabelRowsSizeT     = labels->getNumberOfRows();
    const size_t nDataRowsSizeT      = points->getNumberOfRows();
    const size_t nTrainFeaturesSizeT = points->getNumberOfColumns();

    DAAL_CHECK(nQueryRowsSizeT <= maxInt32AsSizeT, services::ErrorIncorrectNumberOfRowsInInputNumericTable);
    DAAL_CHECK(nLabelRowsSizeT <= maxInt32AsSizeT, services::ErrorIncorrectNumberOfRowsInInputNumericTable);
    DAAL_CHECK(nDataRowsSizeT <= maxInt32AsSizeT, services::ErrorIncorrectNumberOfRowsInInputNumericTable)
    DAAL_CHECK(nTrainFeaturesSizeT <= maxInt32AsSizeT, services::ErrorIncorrectNumberOfColumnsInInputNumericTable);
    DAAL_CHECK(nTrainFeaturesSizeT == nQueryFeaturesSizeT, services::ErrorIncorrectNumberOfColumnsInInputNumericTable);

    const uint32_t nQueryRows = static_cast<uint32_t>(nQueryRowsSizeT);
    const uint32_t nLabelRows = static_cast<uint32_t>(nLabelRowsSizeT);
    const uint32_t nDataRows  = static_cast<uint32_t>(nDataRowsSizeT < nLabelRowsSizeT ? nDataRowsSizeT : nLabelRowsSizeT);
    const uint32_t nFeatures  = static_cast<uint32_t>(nTrainFeaturesSizeT);

    // Block dimensions below are optimal for GEN9
    // Number of doubles is to 2X less against floats
    // to keep the same block size in bytes
    const uint32_t maxDataBlockRowCount  = 4096 * 4;
    const uint32_t maxQueryBlockRowCount = (2048 * 4) / sizeof(algorithmFpType);
    DAAL_CHECK(k <= maxDataBlockRowCount, services::ErrorIncorrectParameter);

    // Maximal number of partial selections to be merged at once
    const uint32_t selectionMaxNumberOfChunks = 16;
    const uint32_t histogramSize              = 256;

    DAAL_OVERFLOW_CHECK_BY_MULTIPLICATION(uint32_t, maxDataBlockRowCount, maxQueryBlockRowCount);
    DAAL_OVERFLOW_CHECK_BY_MULTIPLICATION(uint32_t, maxQueryBlockRowCount, k);
    DAAL_OVERFLOW_CHECK_BY_MULTIPLICATION(uint32_t, maxQueryBlockRowCount * k, selectionMaxNumberOfChunks);
    DAAL_OVERFLOW_CHECK_BY_MULTIPLICATION(uint32_t, maxQueryBlockRowCount, histogramSize);

    auto dataSumOfSquares = context.allocate(TypeIds::id<algorithmFpType>(), maxDataBlockRowCount, st);
    DAAL_CHECK_STATUS_VAR(st);
    auto distances = context.allocate(TypeIds::id<algorithmFpType>(), maxDataBlockRowCount * maxQueryBlockRowCount, st);
    DAAL_CHECK_STATUS_VAR(st);
    auto partialDistances = context.allocate(TypeIds::id<algorithmFpType>(), maxQueryBlockRowCount * k * selectionMaxNumberOfChunks, st);
    DAAL_CHECK_STATUS_VAR(st);
    auto partialLabels = context.allocate(TypeIds::id<int>(), maxQueryBlockRowCount * k * selectionMaxNumberOfChunks, st);
    DAAL_CHECK_STATUS_VAR(st);
    auto sortedLabels = context.allocate(TypeIds::id<int>(), maxQueryBlockRowCount * k, st);
    DAAL_CHECK_STATUS_VAR(st);
    // temporary buffer for RADIX sort
    auto radixBuffer = context.allocate(TypeIds::id<int>(), maxQueryBlockRowCount * histogramSize, st);
    DAAL_CHECK_STATUS_VAR(st);

    const uint32_t nDataBlockCount      = nDataRows / maxDataBlockRowCount + uint32_t(nDataRows % maxDataBlockRowCount != 0);
    const uint32_t nQueryBlockCount     = nQueryRows / maxQueryBlockRowCount + uint32_t(nQueryRows % maxQueryBlockRowCount != 0);
    const uint32_t nSelectionBlockCount = nDataBlockCount / selectionMaxNumberOfChunks + uint32_t(nDataBlockCount % selectionMaxNumberOfChunks != 0);
    SelectIndexed::Result selectResult(context, k, maxQueryBlockRowCount, distances.type(), st);
    DAAL_CHECK_STATUS_VAR(st);

    SelectIndexed::Params params(k, TypeIds::id<algorithmFpType>(), maxDataBlockRowCount, parameter->engine);
    SelectIndexedFactory factory;
    SharedPtr<SelectIndexed> selector(factory.create(k, params, st));
    DAAL_CHECK_STATUS_VAR(st);

    for (uint32_t qblock = 0; qblock < nQueryBlockCount; qblock++)
    {
        Range curQueryRange = Range::createFromBlock(qblock, maxQueryBlockRowCount, nQueryRows);
        BlockDescriptor<algorithmFpType> queryRows;
        DAAL_CHECK_STATUS_VAR(ntData->getBlockOfRows(curQueryRange.startIndex, curQueryRange.count, readOnly, queryRows));
        auto curQuery = queryRows.getBuffer();
        for (uint32_t sblock = 0; sblock < nSelectionBlockCount; sblock++)
        {
            uint32_t curSelectionMaxNumberOfChunks = sblock == 0 ? selectionMaxNumberOfChunks : selectionMaxNumberOfChunks - 1;
            uint32_t selectionChunkCount           = uint32_t(sblock != 0);
            Range curDataBlockRange                = Range::createFromBlock(sblock, curSelectionMaxNumberOfChunks, nDataBlockCount);
            for (uint32_t dblock = curDataBlockRange.startIndex; dblock < curDataBlockRange.endIndex; dblock++)
            {
                Range curDataRange = Range::createFromBlock(dblock, maxDataBlockRowCount, nDataRows);
                BlockDescriptor<int> labelRows;
                DAAL_CHECK_STATUS_VAR(labels->getBlockOfRows(curDataRange.startIndex, curDataRange.count, readOnly, labelRows));
                BlockDescriptor<algorithmFpType> dataRows;
                DAAL_CHECK_STATUS_VAR(points->getBlockOfRows(curDataRange.startIndex, curDataRange.count, readOnly, dataRows));
                // Collect sums of squares from train data
                auto sumResult = math::SumReducer::sum(math::Layout::RowMajor, dataRows.getBuffer(), curDataRange.count, nFeatures, st);
                DAAL_CHECK_STATUS_VAR(st);
                // Initialize GEMM distances
                DAAL_CHECK_STATUS_VAR(scatterSumOfSquares(context, sumResult.sumOfSquares, curDataRange.count, curQueryRange.count, distances));
                // Let's calculate distances using GEMM
                DAAL_CHECK_STATUS_VAR(
                    computeDistances(context, dataRows.getBuffer(), curQuery, distances, curDataRange.count, curQueryRange.count, nFeatures));
                // Select k smallest distances and their labels from every row of the [curQueryRange.count]x[curDataRange.count] block
                DAAL_CHECK_STATUS_VAR(selector->selectNearestDistancesAndLabels(distances, labelRows.getBuffer(), k, curQueryRange.count,
                                                                                curDataRange.count, curDataRange.count, 0, selectResult));
                DAAL_CHECK_STATUS_VAR(st);
                // copy block results to buffer in order to get merged with the same selection algorithm (up to selectionMaxNumberOfChunks of partial results)
                // and keep the first part containing previously merged result if exists
                DAAL_CHECK_STATUS_VAR(copyPartialDistancesAndLabels(context, selectResult.values, selectResult.indices, partialDistances,
                                                                    partialLabels, curQueryRange.count, k, selectionChunkCount,
                                                                    selectionMaxNumberOfChunks));
                DAAL_CHECK_STATUS_VAR(labels->releaseBlockOfRows(labelRows));
                DAAL_CHECK_STATUS_VAR(points->releaseBlockOfRows(dataRows));
                selectionChunkCount++;
            }
            // merge partial data by one more K-selection
            DAAL_CHECK_STATUS_VAR(selector->selectNearestDistancesAndLabels(partialDistances, partialLabels, k, curQueryRange.count,
                                                                            k * curDataBlockRange.count, k * selectionMaxNumberOfChunks,
                                                                            k * selectionMaxNumberOfChunks, selectResult));
        }
        // sort labels of closest neighbors
        st |= RadixSort::sort(selectResult.indices, sortedLabels, radixBuffer, curQueryRange.count, k, k);
        DAAL_CHECK_STATUS_VAR(st);
        BlockDescriptor<algorithmFpType> labelsBlock;
        DAAL_CHECK_STATUS_VAR(y->getBlockOfRows(curQueryRange.startIndex, curQueryRange.count, writeOnly, labelsBlock));
        // search for maximum occurrence label
        DAAL_CHECK_STATUS_VAR(computeWinners(context, sortedLabels, curQueryRange.count, k, labelsBlock.getBuffer()));
        DAAL_CHECK_STATUS_VAR(y->releaseBlockOfRows(labelsBlock));
        DAAL_CHECK_STATUS_VAR(ntData->releaseBlockOfRows(queryRows));
    }
    return st;
}
template <typename algorithmFpType>
services::Status KNNClassificationPredictKernelUCAPI<algorithmFpType>::copyPartialDistancesAndLabels(
    ExecutionContextIface & context, const UniversalBuffer & distances, const UniversalBuffer & labels, UniversalBuffer & partialDistances,
    UniversalBuffer & partialLabels, uint32_t queryBlockRows, uint32_t k, uint32_t nChunk, uint32_t totalNumberOfChunks)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.copyPartialSelections);

    services::Status st;
    auto & kernelFactory = context.getClKernelFactory();
    DAAL_CHECK_STATUS_VAR(buildProgram(kernelFactory));
    auto kernel = kernelFactory.getKernel("copy_partial_selection", st);
    DAAL_CHECK_STATUS_VAR(st);

    DAAL_ASSERT_UNIVERSAL_BUFFER(distances, algorithmFpType, queryBlockRows * k);
    DAAL_ASSERT_UNIVERSAL_BUFFER(labels, int, queryBlockRows * k);
    DAAL_ASSERT_UNIVERSAL_BUFFER(partialDistances, algorithmFpType, queryBlockRows * k * totalNumberOfChunks);
    DAAL_ASSERT_UNIVERSAL_BUFFER(partialLabels, int, queryBlockRows * k * totalNumberOfChunks);

    KernelArguments args(7, st);
    DAAL_CHECK_STATUS_VAR(st);

    args.set(0, distances, AccessModeIds::read);
    args.set(1, labels, AccessModeIds::read);
    args.set(2, partialDistances, AccessModeIds::readwrite);
    args.set(3, partialLabels, AccessModeIds::readwrite);
    args.set(4, static_cast<int32_t>(k));
    args.set(5, static_cast<int32_t>(nChunk));
    args.set(6, static_cast<int32_t>(totalNumberOfChunks));

    KernelRange localRange(1, 1);
    KernelRange globalRange(queryBlockRows, k);

    KernelNDRange range(2);
    range.global(globalRange, st);
    DAAL_CHECK_STATUS_VAR(st);
    range.local(localRange, st);
    DAAL_CHECK_STATUS_VAR(st);
    context.run(range, kernel, args, st);
    DAAL_CHECK_STATUS_VAR(st);
    return st;
}

template <typename algorithmFpType>
services::Status KNNClassificationPredictKernelUCAPI<algorithmFpType>::scatterSumOfSquares(ExecutionContextIface & context,
                                                                                           const UniversalBuffer & dataSumOfSquares,
                                                                                           uint32_t dataBlockRowCount, uint32_t queryBlockRowCount,
                                                                                           UniversalBuffer & distances)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.scatterSumOfSquares);
    DAAL_CHECK(dataBlockRowCount <= maxInt32AsUint32T, services::ErrorBufferSizeIntegerOverflow);

    services::Status st;
    auto & kernelFactory = context.getClKernelFactory();
    DAAL_CHECK_STATUS_VAR(buildProgram(kernelFactory));
    auto kernel = kernelFactory.getKernel("scatter_row", st);
    DAAL_CHECK_STATUS_VAR(st);

    DAAL_ASSERT_UNIVERSAL_BUFFER(dataSumOfSquares, algorithmFpType, dataBlockRowCount);
    DAAL_ASSERT_UNIVERSAL_BUFFER(distances, algorithmFpType, dataBlockRowCount * queryBlockRowCount);

    KernelArguments args(3, st);
    DAAL_CHECK_STATUS_VAR(st);
    args.set(0, dataSumOfSquares, AccessModeIds::read);
    args.set(1, distances, AccessModeIds::write);
    args.set(2, static_cast<int32_t>(dataBlockRowCount));

    KernelRange globalRange(dataBlockRowCount, queryBlockRowCount);
    context.run(globalRange, kernel, args, st);
    DAAL_CHECK_STATUS_VAR(st);
    return st;
}

template <typename algorithmFpType>
services::Status KNNClassificationPredictKernelUCAPI<algorithmFpType>::computeDistances(ExecutionContextIface & context,
                                                                                        const services::internal::Buffer<algorithmFpType> & data,
                                                                                        const services::internal::Buffer<algorithmFpType> & query,
                                                                                        UniversalBuffer & distances, uint32_t dataBlockRowCount,
                                                                                        uint32_t queryBlockRowCount, uint32_t nFeatures)

{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.GEMM);
    DAAL_ASSERT_UNIVERSAL_BUFFER(distances, algorithmFpType, queryBlockRowCount * dataBlockRowCount);
    DAAL_ASSERT(data.size() >= dataBlockRowCount * nFeatures);
    DAAL_ASSERT(query.size() >= queryBlockRowCount * nFeatures);
    return BlasGpu<algorithmFpType>::xgemm(math::Layout::RowMajor, math::Transpose::NoTrans, math::Transpose::Trans, queryBlockRowCount,
                                           dataBlockRowCount, nFeatures, algorithmFpType(-2.0), query, nFeatures, 0, data, nFeatures, 0,
                                           algorithmFpType(1.0), distances.get<algorithmFpType>(), dataBlockRowCount, 0);
}

template <typename algorithmFpType>
services::Status KNNClassificationPredictKernelUCAPI<algorithmFpType>::computeWinners(ExecutionContextIface & context, const UniversalBuffer & labels,
                                                                                      uint32_t queryBlockRowCount, uint32_t k,
                                                                                      UniversalBuffer labelsOut)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.computeWinners);

    services::Status st;
    auto & kernelFactory = context.getClKernelFactory();
    DAAL_CHECK_STATUS_VAR(buildProgram(kernelFactory));
    auto kernel = kernelFactory.getKernel("find_max_occurance", st);
    DAAL_CHECK_STATUS_VAR(st);

    DAAL_ASSERT_UNIVERSAL_BUFFER(labels, int, queryBlockRowCount * k);
    DAAL_ASSERT_UNIVERSAL_BUFFER(labelsOut, algorithmFpType, queryBlockRowCount);

    KernelArguments args(3, st);
    DAAL_CHECK_STATUS_VAR(st);
    args.set(0, labels, AccessModeIds::read);
    args.set(1, labelsOut, AccessModeIds::write);
    args.set(2, static_cast<int32_t>(k));

    KernelRange localRange(1);
    KernelRange globalRange(queryBlockRowCount);

    KernelNDRange range(1);
    range.global(globalRange, st);
    DAAL_CHECK_STATUS_VAR(st);
    range.local(localRange, st);
    DAAL_CHECK_STATUS_VAR(st);
    context.run(range, kernel, args, st);
    DAAL_CHECK_STATUS_VAR(st);
    return st;
}

template <typename algorithmFpType>
services::Status KNNClassificationPredictKernelUCAPI<algorithmFpType>::buildProgram(ClKernelFactoryIface & kernelFactory)
{
    auto fptypeName   = services::internal::sycl::getKeyFPType<algorithmFpType>();
    auto buildOptions = fptypeName;
    buildOptions.add(" -D sortedType=int -D NumParts=16 ");

    services::String cachekey("__daal_algorithms_bf_knn_block_");
    cachekey.add(fptypeName);
    cachekey.add(buildOptions);

    services::Status st;
    {
        DAAL_ITTNOTIFY_SCOPED_TASK(compute.buildProgram);
        kernelFactory.build(ExecutionTargetIds::device, cachekey.c_str(), bf_knn_cl_kernels, buildOptions.c_str(), st);
        DAAL_CHECK_STATUS_VAR(st);
    }
    return st;
}

} // namespace internal
} // namespace prediction
} // namespace bf_knn_classification
} // namespace algorithms
} // namespace daal

#endif
