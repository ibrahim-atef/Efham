import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:webinar/app/pages/main_page/categories_page/filter_category_page/filter_category_page.dart';
import 'package:webinar/app/providers/app_language_provider.dart';
import 'package:webinar/app/providers/drawer_provider.dart';
import 'package:webinar/app/services/guest_service/categories_service.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/data/app_language.dart';
import 'package:webinar/common/shimmer_component.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/config/colors.dart';
import 'package:webinar/config/styles.dart';
import 'package:webinar/locator.dart';

import '../../../../common/utils/object_instance.dart';
import '../../../models/category_model.dart';
import '../../../../common/components.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {

  bool isLoading = true;
  List<CategoryModel> trendCategories = [];
  List<CategoryModel> categories = [];

  @override
  void initState() {
    super.initState();
    
    
    Future.wait([getCategoriesData(),getTrendCategoriessData()]).then((value) {
      setState(() {
        isLoading = false;
      });
    });   
  }

  Future getCategoriesData() async {
    categories = await CategoriesService.categories();
  }
  
  Future getTrendCategoriessData() async {
    trendCategories = await CategoriesService.trendCategories();
  }

  Widget buildCategoryItem(CategoryModel category, int level) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: getSize().width,
        padding: EdgeInsetsDirectional.only(
          start: 5.0 * level,
          end: 16,
          top: 8,
          bottom: 8,
        ),
        child: Column(
          children: [
            // المسافة العلوية
            if (level == 0) space(16),

            GestureDetector(
              onTap: () {
                if ((category.subCategories?.isEmpty ?? true)) {
                  nextRoute(FilterCategoryPage.pageName, arguments: category);
                } else {
                  setState(() {
                    category.isOpen = !category.isOpen;
                  });
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  // icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: greyF8,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Image.network(
                      category.icon ?? '',
                      width: 22,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error, color: Colors.red[200], size: 22);
                      },
                    ),
                  ),

                  space(0, width: 10),

                  // Title & count inside Expanded to prevent overflow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.title ?? '',
                          style: style14Bold(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${category.webinarsCount ?? 0} ${appText.courses}',
                          style: style12Regular().copyWith(color: greyA5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  if (category.subCategories?.isNotEmpty ?? false)
                    AnimatedRotation(
                      turns: category.isOpen
                          ? 90 / 360
                          : locator<AppLanguage>().isRtl()
                          ? 180 / 360
                          : 0,
                      duration: const Duration(milliseconds: 200),
                      child: SvgPicture.asset(AppAssets.arrowRightSvg),
                    ),
                
                ],
              )

            ),

            // Subcategories
            AnimatedCrossFade(
              firstChild: Stack(
                children: [
                  // dashed line
                  if (level > 0)
                    PositionedDirectional(
                      start: 15,
                      top: 0,
                      bottom: 35,
                      child: CustomPaint(
                        size: const Size(.5, double.infinity),
                        painter: DashedLineVerticalPainter(),
                        child: const SizedBox(),
                      ),
                    ),

                  Column(
                    children: List.generate(
                      category.subCategories?.length ?? 0,
                          (i) => buildCategoryItem(category.subCategories![i], level + 1),
                    ),
                  ),
                ],
              ),
              secondChild: SizedBox(width: getSize().width),
              crossFadeState:
              category.isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),

            space(15),

            Container(
              width: getSize().width,
              height: 1,
              color: greyF8,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLastLayerSubCategory(CategoryModel category) {
    if (category.subCategories == null || category.subCategories!.isEmpty) {
      return GestureDetector(
        onTap: () {
          nextRoute(FilterCategoryPage.pageName, arguments: category);
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Circle indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: greyE7, width: 1),
                  shape: BoxShape.circle,
                ),
              ),
              space(0, width: 22),
              // Subcategory details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title ?? '',
                      style: style14Bold(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category.webinarsCount == 0
                          ? appText.noCourse
                          : '${category.webinarsCount} ${appText.courses}',
                      style: style12Regular().copyWith(color: greyA5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Column(
        children: category.subCategories!
            .map((subCategory) => buildLastLayerSubCategory(subCategory))
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguageProvider>(
      builder: (context, appLanguageProvider,_) {
        
        return directionality(
          child: Consumer<DrawerProvider>(
            builder: (context, drawerProvider, _) {
              
              return ClipRRect(
                borderRadius: borderRadius(radius:  drawerProvider.isOpenDrawer ? 20 : 0),
                child: Scaffold(
                  backgroundColor: greyFA,
                  
                  appBar: appbar(
                    title: appText.categories,
                    leftIcon: AppAssets.menuSvg,
                    onTapLeftIcon: (){
                      drawerController.showDrawer();
                    }
                  ),
                
                  body: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                
                        space(15),
                
                        Padding(
                          padding: padding(),
                          child: Text(
                            appText.trending,
                            style: style16Regular(),
                          ),
                        ),
                
                        space(14),
                
                        // trend categories
                        SizedBox(
                          width: getSize().width,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: padding(),
                            child: Row(
                              children: List.generate( isLoading ? 3 : trendCategories.length, (index) {
                                return isLoading
                                  ? horizontalCategoryItemShimmer()
                                  : horizontalCategoryItem(
                                      trendCategories[index].color ?? blueF2(),
                                      trendCategories[index].icon ?? '', 
                                      trendCategories[index].title ?? '', 
                                      trendCategories[index].webinarsCount?.toString() ?? '0', 
                                      (){
                                        nextRoute(FilterCategoryPage.pageName, arguments: trendCategories[index]);
                                      }
                                    );
                              }),
                            ),
                          ),
                        ),
                
                        space(30),
                
                        Padding(
                          padding: padding(),
                          child: Text(
                            appText.browseCategories,
                            style: style16Regular().copyWith(color: grey3A),
                          ),
                        ),
                
                        space(14),
                
                        // categories
                        Container(
                          width: getSize().width,
                          margin: padding(),
                
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: borderRadius(),
                          ),
                
                          child: Column(
                            children: [
                              //
                              // ...List.generate(isLoading ? 8 : categories.length, (index) {
                              //
                              //   return isLoading
                              //     ? categoryItemShimmer()
                              //     : Container(
                              //         width: getSize().width,
                              //         padding: padding(),
                              //         child: Column(
                              //           children: [
                              //             space(16),
                              //
                              //             // category
                              //             GestureDetector(
                              //               onTap: (){
                              //
                              //                 if((categories[index].subCategories?.isEmpty ?? false)){
                              //                   nextRoute(FilterCategoryPage.pageName, arguments: categories[index]);
                              //                 }else{
                              //                   setState(() {
                              //                     categories[index].isOpen = !categories[index].isOpen;
                              //                   });
                              //                 }
                              //
                              //               },
                              //               behavior: HitTestBehavior.opaque,
                              //               child: Row(
                              //                 children: [
                              //
                              //                   Container(
                              //                     width: 34,
                              //                     height: 34,
                              //                     decoration: BoxDecoration(
                              //                       color: greyF8,
                              //                       shape: BoxShape.circle,
                              //                     ),
                              //                     alignment: Alignment.center,
                              //                     child: Image.network(
                              //                       categories[index].icon ?? '',
                              //                       width: 22,
                              //                       errorBuilder: (context, error, stackTrace) {
                              //                         return Icon(Icons.error, color: Colors.red[200], size: 22);
                              //                       },
                              //                     ),
                              //                   ),
                              //
                              //
                              //                   space(0,width: 10),
                              //
                              //                   Column(
                              //                     crossAxisAlignment: CrossAxisAlignment.start,
                              //                     mainAxisAlignment: MainAxisAlignment.center,
                              //                     children: [
                              //
                              //                       Text(
                              //                         categories[index].title ?? '',
                              //                         style: style14Bold(),
                              //                       ),
                              //
                              //                       Text(
                              //                         '${categories[index].webinarsCount} ${appText.courses}',
                              //                         style: style12Regular().copyWith(color: greyA5),
                              //                       ),
                              //
                              //                     ],
                              //                   ),
                              //
                              //
                              //                   const Spacer(),
                              //
                              //                   if(categories[index].subCategories?.isNotEmpty ?? false)...{
                              //                     AnimatedRotation(
                              //                       turns: categories[index].isOpen
                              //                         ? 90 / 360
                              //                         : locator<AppLanguage>().isRtl()
                              //                           ? 180 / 360
                              //                           : 0,
                              //                       duration: const Duration(milliseconds: 200),
                              //                       child: SvgPicture.asset(
                              //                         AppAssets.arrowRightSvg
                              //
                              //                       ),
                              //                     )
                              //
                              //                   }
                              //
                              //
                              //                 ],
                              //               ),
                              //
                              //             ),
                              //
                              //
                              //             // subCategories
                              //             AnimatedCrossFade(
                              //               firstChild: Stack(
                              //                 children: [
                              //
                              //                   // vertical dash
                              //                   PositionedDirectional(
                              //                     start: 15,
                              //                     top: 0,
                              //                     bottom: 35,
                              //                     child: CustomPaint(
                              //                       size: const Size(.5, double.infinity),
                              //                       painter: DashedLineVerticalPainter(),
                              //                       child: const SizedBox(),
                              //                     ),
                              //                   ),
                              //
                              //                   // sub category
                              //                   SizedBox(
                              //                     child: Column(
                              //                       children: List.generate(categories[index].subCategories?.length ?? 0, (i) {
                              //                         return GestureDetector(
                              //                           onTap: (){
                              //                             nextRoute(FilterCategoryPage.pageName, arguments: categories[index].subCategories![i]);
                              //                           },
                              //                           behavior: HitTestBehavior.opaque,
                              //                           child: Column(
                              //                             children: [
                              //                               space(15),
                              //
                              //                               // sub categories item
                              //                               Padding(
                              //                                 padding: padding(horizontal: 10),
                              //                                 child: Row(
                              //                                   children: [
                              //
                              //                                     // circle
                              //                                     Container(
                              //                                       width: 10,
                              //                                       height: 10,
                              //                                       decoration: BoxDecoration(
                              //                                         color: Colors.white,
                              //                                         border: Border.all(
                              //                                           color: greyE7,
                              //                                           width: 1
                              //                                         ),
                              //                                         shape: BoxShape.circle
                              //                                       ),
                              //                                     ),
                              //
                              //                                     space(0,width: 22),
                              //
                              //                                     // sub category details
                              //                                     Column(
                              //                                       crossAxisAlignment: CrossAxisAlignment.start,
                              //                                       mainAxisAlignment: MainAxisAlignment.center,
                              //                                       children: [
                              //
                              //                                         Text(
                              //                                           categories[index].subCategories?[i].title ?? '',
                              //                                           style: style14Bold(),
                              //                                           maxLines: 1,
                              //                                         ),
                              //
                              //                                         Text(
                              //                                           categories[index].subCategories?[i].webinarsCount == 0
                              //                                           ? appText.noCourse
                              //                                           : '${categories[index].subCategories?[i].webinarsCount} ${appText.courses}',
                              //                                           style: style12Regular().copyWith(color: greyA5),
                              //                                         ),
                              //
                              //                                       ],
                              //                                     ),
                              //                                   ],
                              //                                 ),
                              //                               ),
                              //
                              //                               space(15),
                              //                             ],
                              //                           ),
                              //                         );
                              //                       }),
                              //                     ),
                              //                   )
                              //                 ],
                              //               ),
                              //               secondChild: SizedBox(width: getSize().width,),
                              //               crossFadeState: categories[index].isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                              //               duration: const Duration(milliseconds: 300)
                              //             ),
                              //
                              //             space(15),
                              //
                              //             Container(
                              //               width: getSize().width,
                              //               height: 1,
                              //               decoration: BoxDecoration(color: greyF8),
                              //             )
                              //           ],
                              //         ),
                              //       );
                              //
                              // }),


                              ...List.generate(
                                categories.length,
                                    (index) => buildCategoryItem(categories[index], 0),
                              )
                              // ...List.generate(
                              //   categories.length,
                              //       (index) => buildLastLayerSubCategory(categories[index]),
                              // )

                            ],
                          ),
                        ),
                
                
                        space(120),
                      ],
                    ),
                  ),
                ),
              );
            }
          )
        );
      }
    );
  }


}

class DashedLineVerticalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 6, dashSpace = 5, startY = 0;
    final paint = Paint()
      ..color = Colors.grey.withOpacity(.5)
      ..strokeWidth = .4;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}