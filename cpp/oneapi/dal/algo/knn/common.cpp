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

#include "oneapi/dal/algo/knn/common.hpp"
#include "oneapi/dal/algo/knn/backend/model_impl.hpp"
#include "oneapi/dal/exceptions.hpp"

namespace oneapi::dal::knn {

template <>
class detail::descriptor_impl<task::classification> : public base {
public:
    std::int64_t class_count = 2;
    std::int64_t neighbor_count = 1;
};

using detail::descriptor_impl;
using detail::model_impl;

template <typename Task>
descriptor_base<Task>::descriptor_base() : impl_(new descriptor_impl<Task>{}) {}

template <>
std::int64_t descriptor_base<task::classification>::get_class_count() const {
    return impl_->class_count;
}

template <>
std::int64_t descriptor_base<task::classification>::get_neighbor_count() const {
    return impl_->neighbor_count;
}

template <>
void descriptor_base<task::classification>::set_class_count_impl(std::int64_t value) {
    if (value < 2) {
        throw domain_error("class_count should be > 1");
    }
    impl_->class_count = value;
}

template <>
void descriptor_base<task::classification>::set_neighbor_count_impl(std::int64_t value) {
    if (value < 1) {
        throw domain_error("neighbor_count should be > 0");
    }
    impl_->neighbor_count = value;
}

class empty_model_impl : public detail::model_impl {};

template <typename Task>
model<Task>::model() : impl_(new empty_model_impl{}) {}

template <typename Task>
model<Task>::model(const std::shared_ptr<detail::model_impl>& impl) : impl_(impl) {}

template class ONEDAL_EXPORT descriptor_base<task::classification>;
template class ONEDAL_EXPORT model<task::classification>;

} // namespace oneapi::dal::knn
