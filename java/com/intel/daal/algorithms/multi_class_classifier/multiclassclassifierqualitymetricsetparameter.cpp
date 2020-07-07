/* file: multiclassclassifierqualitymetricsetparameter.cpp */
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

/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
#include "daal.h"
#include "com_intel_daal_algorithms_multi_class_classifier_quality_metric_set_QualityMetricSetParameter.h"

using namespace daal::algorithms::multi_class_classifier::quality_metric_set;

/*
 * Class:     com_intel_daal_algorithms_multi_class_classifier_quality_metric_set_QualityMetricSetParameter
 * Method:    cSetNClasses
 * Signature: (JJ)V
 */
JNIEXPORT void JNICALL Java_com_intel_daal_algorithms_multi_1class_1classifier_quality_1metric_1set_QualityMetricSetParameter_cSetNClasses(
    JNIEnv *, jobject, jlong parAddr, jlong nClasses)
{
    (*(Parameter *)parAddr).nClasses = nClasses;
}

/*
 * Class:     com_intel_daal_algorithms_multi_class_classifier_quality_metric_set_QualityMetricSetParameter
 * Method:    cGetNClasses
 * Signature: (J)J
 */
JNIEXPORT jlong JNICALL Java_com_intel_daal_algorithms_multi_1class_1classifier_quality_1metric_1set_QualityMetricSetParameter_cGetNClasses(
    JNIEnv *, jobject, jlong parAddr)
{
    return (jlong)(*(Parameter *)parAddr).nClasses;
}