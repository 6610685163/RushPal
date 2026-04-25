
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rushpal/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 25, // ขนาดเริ่มต้น
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryPink.withOpacity(
        0.2,
      ), // สีพื้นหลังตอนรอโหลด
      // ถ้ามี URL ให้โหลดรูปมาแสดง
      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImageProvider(imageUrl!)
          : null,

      // ถ้าไม่มี URL (ยังไม่อัปรูป) ให้แสดงไอคอนคน
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Icon(
              Icons.person,
              size: radius, // ให้ไอคอนใหญ่ตามกรอบ
              color: AppTheme.primaryPink,
            )
          : null,
    );
  }
}
