/* file: df_tree_level_build_helper_oneapi.i */
/*******************************************************************************
* Copyright 2020 Intel Corporation
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

/*
//++
// Implementation of common functions for building tree level
//--
*/
#include "src/algorithms/dtrees/forest/oneapi/df_tree_level_build_helper_oneapi.h"
#include "src/algorithms/dtrees/forest/oneapi/cl_kernels/df_tree_level_build_helper_kernels.cl"

#include "src/services/service_data_utils.h"
#include "src/externals/service_ittnotify.h"

using namespace daal::services::internal::sycl;
using namespace daal::services;
using namespace daal::services::internal;

namespace daal
{
namespace algorithms
{
namespace decision_forest
{
namespace internal
{
template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::buildProgram(ClKernelFactoryIface & factory, const char * buildOptions)
{
    services::Status status;
    DAAL_ITTNOTIFY_SCOPED_TASK(treeLevelHelperOneAPI.buildProgram);
    {
        auto fptype_name   = getKeyFPType<algorithmFPType>();
        auto build_options = fptype_name;

        build_options.add(" -cl-std=CL1.2 ");
        if (buildOptions)
        {
            build_options.add(buildOptions);
        }
        build_options.add(" -D BIG_NODE_LOW_BORDER_BLOCKS_NUM=32 -D LOCAL_BUFFER_SIZE=256 -D MAX_WORK_ITEMS_PER_GROUP=256 ");

        services::String cachekey("__daal_algorithms_df_tree_level_build_helper_");
        cachekey.add(build_options);

        factory.build(ExecutionTargetIds::device, cachekey.c_str(), df_tree_level_build_helper_kernels, build_options.c_str(), status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::initializeTreeOrder(size_t nRows, UniversalBuffer & treeOrder)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.initializeTreeOrder);

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(treeOrder, int32_t, nRows);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelInitializeTreeOrder;

    {
        KernelArguments args(1, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, treeOrder, AccessModeIds::write);

        KernelRange global_range(nRows);

        context.run(global_range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::markPresentRows(const UniversalBuffer & rowsList, UniversalBuffer & rowsBuffer,
                                                                              size_t nRows, size_t localSize, size_t nSubgroupSums)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.markPresentRows);
    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(rowsList, int32_t, nRows);
    DAAL_ASSERT_UNIVERSAL_BUFFER(rowsBuffer, int32_t, nRows);

    auto & context = services::internal::getDefaultContext();

    {
        DAAL_ASSERT(nRows <= _int32max);

        auto & kernel = kernelMarkPresentRows;
        KernelArguments args(3, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, rowsList, AccessModeIds::read);
        args.set(1, rowsBuffer, AccessModeIds::write);
        args.set(2, static_cast<int32_t>(nRows));

        KernelRange local_range(localSize);
        KernelRange global_range(localSize * nSubgroupSums);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::countAbsentRowsForBlocks(const UniversalBuffer & rowsBuffer, size_t nRows,
                                                                                       UniversalBuffer & partialSums, size_t localSize,
                                                                                       size_t nSubgroupSums)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.countAbsentRowsForBlocks);
    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(rowsBuffer, int32_t, nRows);
    DAAL_ASSERT_UNIVERSAL_BUFFER(partialSums, int32_t, nSubgroupSums);

    auto & context = services::internal::getDefaultContext();

    {
        DAAL_ASSERT(nRows <= _int32max);

        auto & kernel = kernelCountAbsentRowsForBlocks;
        KernelArguments args(3, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, rowsBuffer, AccessModeIds::read);
        args.set(1, partialSums, AccessModeIds::write);
        args.set(2, static_cast<int32_t>(nRows));

        KernelRange local_range(localSize);
        KernelRange global_range(localSize * nSubgroupSums);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::countAbsentRowsTotal(const UniversalBuffer & partialSums,
                                                                                   UniversalBuffer & partialPrefixSums, UniversalBuffer & totalSum,
                                                                                   size_t localSize, size_t nSubgroupSums)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.countAbsentRowsTotal);
    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(partialSums, int32_t, nSubgroupSums);
    DAAL_ASSERT_UNIVERSAL_BUFFER(partialPrefixSums, int32_t, nSubgroupSums);
    DAAL_ASSERT_UNIVERSAL_BUFFER(totalSum, int32_t, 1);

    auto & context = services::internal::getDefaultContext();

    {
        DAAL_ASSERT(nSubgroupSums <= _int32max);

        auto & kernel = kernelCountAbsentRowsTotal;
        KernelArguments args(4, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, partialSums, AccessModeIds::read);
        args.set(1, partialPrefixSums, AccessModeIds::write);
        args.set(2, totalSum, AccessModeIds::write);
        args.set(3, static_cast<int32_t>(nSubgroupSums));

        KernelRange local_range(localSize);
        KernelRange global_range(localSize);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::fillOOBRowsListByBlocks(const UniversalBuffer & rowsBuffer, size_t nRows,
                                                                                      const UniversalBuffer & partialPrefixSums,
                                                                                      UniversalBuffer & oobRowsList, size_t localSize,
                                                                                      size_t nSubgroupSums, size_t nOOBRows)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.fillOOBRowsListByBlocks);
    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(rowsBuffer, int32_t, nRows);
    DAAL_ASSERT_UNIVERSAL_BUFFER(partialPrefixSums, int32_t, nSubgroupSums);
    DAAL_ASSERT_UNIVERSAL_BUFFER(oobRowsList, int32_t, nOOBRows);

    auto & context = services::internal::getDefaultContext();

    {
        DAAL_ASSERT(nRows <= _int32max);

        auto & kernel = kernelFillOOBRowsListByBlocks;
        KernelArguments args(4, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, rowsBuffer, AccessModeIds::read);
        args.set(1, partialPrefixSums, AccessModeIds::read);
        args.set(2, oobRowsList, AccessModeIds::write);
        args.set(3, static_cast<int32_t>(nRows));

        KernelRange local_range(localSize);
        KernelRange global_range(localSize * nSubgroupSums);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}
template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::getOOBRows(const UniversalBuffer & rowsList, size_t nRows, size_t & nOOBRows,
                                                                         UniversalBuffer & oobRowsList)
{
    services::Status status;

    auto & context = services::internal::getDefaultContext();

    const int absentMark       = -1;
    const size_t localSize     = _preferableSubGroup;
    const size_t nSubgroupSums = _maxLocalSums * localSize < nRows ? _maxLocalSums : (nRows / localSize + !(nRows / localSize));

    auto rowsBuffer = context.allocate(TypeIds::id<int>(), nRows, status); // it is filled with marks Present/Absent for each rows
    DAAL_CHECK_STATUS_VAR(status);
    auto partialSums = context.allocate(TypeIds::id<int>(), nSubgroupSums, status);
    DAAL_CHECK_STATUS_VAR(status);
    auto partialPrefixSums = context.allocate(TypeIds::id<int>(), nSubgroupSums, status);
    DAAL_CHECK_STATUS_VAR(status);
    auto totalSum = context.allocate(TypeIds::id<int>(), 1, status);
    DAAL_CHECK_STATUS_VAR(status);

    context.fill(rowsBuffer, absentMark, status);
    DAAL_CHECK_STATUS_VAR(status);

    DAAL_CHECK_STATUS_VAR(markPresentRows(rowsList, rowsBuffer, nRows, localSize, nSubgroupSums));
    DAAL_CHECK_STATUS_VAR(countAbsentRowsForBlocks(rowsBuffer, nRows, partialSums, localSize, nSubgroupSums));
    DAAL_CHECK_STATUS_VAR(countAbsentRowsTotal(partialSums, partialPrefixSums, totalSum, localSize, nSubgroupSums));

    auto nOOBRowsHost = totalSum.template get<int>().toHost(ReadWriteMode::readOnly, status);
    DAAL_CHECK_STATUS_VAR(status);

    nOOBRows = static_cast<size_t>(nOOBRowsHost.get()[0]);

    if (nOOBRows > 0)
    {
        // assign buffer of required size to the input oobRowsList buffer
        oobRowsList = context.allocate(TypeIds::id<int>(), nOOBRows, status);
        DAAL_CHECK_STATUS_VAR(status);

        DAAL_CHECK_STATUS_VAR(fillOOBRowsListByBlocks(rowsBuffer, nRows, partialPrefixSums, oobRowsList, localSize, nSubgroupSums, nOOBRows));
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::getNumOfSplitNodes(const UniversalBuffer & nodeList, size_t nNodes,
                                                                                 size_t & nSplitNodes)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.getNumOfSplitNodes);

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeList, int32_t, nNodes * _nNodeProps);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelGetNumOfSplitNodes;

    auto bufNSplitNodes = context.allocate(TypeIds::id<int>(), 1, status);
    DAAL_CHECK_STATUS_VAR(status);

    {
        DAAL_ASSERT(nNodes <= _int32max);

        KernelArguments args(3, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, nodeList, AccessModeIds::read);
        args.set(1, static_cast<int32_t>(nNodes));
        args.set(2, bufNSplitNodes, AccessModeIds::write);

        size_t localSize = _preferableSubGroup;

        // will add more range for it
        KernelRange local_range(localSize);
        KernelRange global_range(localSize);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    auto bufNsplitNodesHost = bufNSplitNodes.template get<int>().toHost(ReadWriteMode::readOnly, status);
    DAAL_CHECK_STATUS_VAR(status);
    nSplitNodes = bufNsplitNodesHost.get()[0];

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::convertSplitToLeaf(UniversalBuffer & nodeList, size_t nNodes)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.convertSplitToLeaf);

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeList, int32_t, nNodes * _nNodeProps);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelConvertSplitToLeaf;

    {
        KernelArguments args(1, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, nodeList, AccessModeIds::readwrite);

        KernelRange global_range(nNodes);

        context.run(global_range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::doNodesSplit(const UniversalBuffer & nodeList, size_t nNodes,
                                                                           UniversalBuffer & nodeListNew, size_t nNodesNew)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.doNodesSplit);

    /*split rows for each nodes in accordance with best split info*/

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeList, int32_t, nNodes * _nNodeProps);
    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeListNew, int32_t, nNodesNew * _nNodeProps);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelDoNodesSplit;

    {
        DAAL_ASSERT(nNodes <= _int32max);

        KernelArguments args(3, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, nodeList, AccessModeIds::read);
        args.set(1, static_cast<int32_t>(nNodes));
        args.set(2, nodeListNew, AccessModeIds::write);

        size_t localSize = _preferableSubGroup;

        // will add more range for it
        KernelRange local_range(localSize);
        KernelRange global_range(localSize);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::splitNodeListOnGroupsBySize(const UniversalBuffer & nodeList, size_t nNodes,
                                                                                          UniversalBuffer & nodesGroups, const size_t nGroups,
                                                                                          const size_t nGroupProps, UniversalBuffer & nodeIndices)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.splitNodeListOnGroupsBySize);

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeList, int32_t, nNodes * _nNodeProps);
    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeIndices, int32_t, nNodes);
    DAAL_ASSERT_UNIVERSAL_BUFFER(nodesGroups, int32_t, nGroups * nGroupProps);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelSplitNodeListOnGroupsBySize;

    {
        DAAL_ASSERT(nNodes <= _int32max);
        DAAL_ASSERT(_minRowsBlock <= _int32max);

        KernelArguments args(5, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, nodeList, AccessModeIds::read);
        args.set(1, static_cast<int32_t>(nNodes));
        args.set(2, nodesGroups, AccessModeIds::write);
        args.set(3, nodeIndices, AccessModeIds::write);
        args.set(4, static_cast<int32_t>(_minRowsBlock));

        size_t localSize = _preferableSubGroup;

        KernelRange local_range(localSize);
        KernelRange global_range(localSize);

        KernelNDRange range(1);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::doLevelPartition(const UniversalBuffer & data, UniversalBuffer & nodeList,
                                                                               size_t nNodes, UniversalBuffer & treeOrder,
                                                                               UniversalBuffer & treeOrderBuf, size_t nRows, size_t nFeatures)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.doLevelPartition);

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(data, uint32_t, nRows * nFeatures);
    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeList, int32_t, nNodes * _nNodeProps);
    DAAL_ASSERT_UNIVERSAL_BUFFER(treeOrder, int32_t, nRows);
    DAAL_ASSERT_UNIVERSAL_BUFFER(treeOrderBuf, int32_t, nRows);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelDoLevelPartition;

    {
        DAAL_ASSERT(nFeatures <= _int32max);

        KernelArguments args(5, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, data, AccessModeIds::read);
        args.set(1, nodeList, AccessModeIds::read);
        args.set(2, treeOrder, AccessModeIds::read);
        args.set(3, treeOrderBuf, AccessModeIds::write);
        args.set(4, static_cast<int32_t>(nFeatures));

        size_t localSize = _preferableSubGroup;

        KernelRange local_range(localSize, 1);
        KernelRange global_range(localSize, nNodes);

        KernelNDRange range(2);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    DAAL_CHECK_STATUS_VAR(partitionCopy(treeOrderBuf, treeOrder, 0, nRows));

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::partitionCopy(UniversalBuffer & treeOrderBuf, UniversalBuffer & treeOrder,
                                                                            size_t iStart, size_t nRows)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.partitionCopy);

    services::Status status;

    DAAL_ASSERT_UNIVERSAL_BUFFER(treeOrder, int32_t, nRows);
    DAAL_ASSERT_UNIVERSAL_BUFFER(treeOrderBuf, int32_t, nRows);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelPartitionCopy;

    {
        DAAL_ASSERT(iStart <= _int32max);

        KernelArguments args(3, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, treeOrderBuf, AccessModeIds::read);
        args.set(1, treeOrder, AccessModeIds::write);
        args.set(2, static_cast<int32_t>(iStart));

        KernelRange global_range(nRows);

        context.run(global_range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::updateMDIVarImportance(const UniversalBuffer & nodeList,
                                                                                     const UniversalBuffer & nodeImpDecreaseList, size_t nNodes,
                                                                                     services::internal::Buffer<algorithmFPType> & varImp,
                                                                                     size_t nFeatures)
{
    DAAL_ITTNOTIFY_SCOPED_TASK(compute.updateMDIVarImportance);

    services::Status status;

    DAAL_ASSERT(varImp.size() == nFeatures);

    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeList, int32_t, nNodes * _nNodeProps);
    DAAL_ASSERT_UNIVERSAL_BUFFER(nodeImpDecreaseList, algorithmFPType, nNodes);

    auto & context = services::internal::getDefaultContext();

    auto & kernel = kernelUpdateMDIVarImportance;

    {
        DAAL_ASSERT(nNodes <= _int32max);

        KernelArguments args(4, status);
        DAAL_CHECK_STATUS_VAR(status);
        args.set(0, nodeList, AccessModeIds::read);
        args.set(1, nodeImpDecreaseList, AccessModeIds::read);
        args.set(2, static_cast<int32_t>(nNodes));
        args.set(3, varImp, AccessModeIds::write);

        int localSize = _preferableGroupSize;
        //calculating local size in way to have all subgroups for node in one group to use local buffer
        while (localSize > nNodes && localSize > _preferableSubGroup)
        {
            localSize >>= 1;
        }

        KernelRange local_range(localSize, 1);
        KernelRange global_range(localSize, nFeatures);

        KernelNDRange range(2);
        range.local(local_range, status);
        DAAL_CHECK_STATUS_VAR(status);
        range.global(global_range, status);
        DAAL_CHECK_STATUS_VAR(status);

        context.run(range, kernel, args, status);
        DAAL_CHECK_STATUS_VAR(status);
    }

    return status;
}

///////////////////////////////////////////////////////////////////////////////////////////
/* init method for TreeLevelBuildHelperOneAPI */
///////////////////////////////////////////////////////////////////////////////////////////
template <typename algorithmFPType>
services::Status TreeLevelBuildHelperOneAPI<algorithmFPType>::init(const char * buildOptions, size_t nNodeProps)
{
    services::Status status;

    _nNodeProps = nNodeProps;

    auto & context        = services::internal::getDefaultContext();
    auto & kernel_factory = context.getClKernelFactory();

    DAAL_CHECK_STATUS_VAR(buildProgram(kernel_factory, buildOptions));

    kernelInitializeTreeOrder = kernel_factory.getKernel("initializeTreeOrder", status);
    kernelPartitionCopy       = kernel_factory.getKernel("partitionCopy", status);

    kernelConvertSplitToLeaf          = kernel_factory.getKernel("convertSplitToLeaf", status);
    kernelGetNumOfSplitNodes          = kernel_factory.getKernel("getNumOfSplitNodes", status);
    kernelDoNodesSplit                = kernel_factory.getKernel("doNodesSplit", status);
    kernelDoLevelPartition            = kernel_factory.getKernel("doLevelPartition", status);
    kernelSplitNodeListOnGroupsBySize = kernel_factory.getKernel("splitNodeListOnGroupsBySize", status);

    kernelMarkPresentRows          = kernel_factory.getKernel("markPresentRows", status);
    kernelCountAbsentRowsForBlocks = kernel_factory.getKernel("countAbsentRowsForBlocks", status);
    kernelCountAbsentRowsTotal     = kernel_factory.getKernel("countAbsentRowsTotal", status);
    kernelFillOOBRowsListByBlocks  = kernel_factory.getKernel("fillOOBRowsListByBlocks", status);
    kernelUpdateMDIVarImportance   = kernel_factory.getKernel("updateMDIVarImportance", status);

    DAAL_CHECK_STATUS_VAR(status);

    return status;
}

} /* namespace internal */
} /* namespace decision_forest */
} /* namespace algorithms */
} /* namespace daal */
