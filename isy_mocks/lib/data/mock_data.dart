import '../models/app_user.dart';
import '../models/comment.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/reaction.dart';

/// Datos de ejemplo (seed) para los mocks. Cada getter devuelve copias frescas
/// y mutables para que los controladores tengan su propio estado.
class MockData {
  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) {
    return DateTime.now()
        .subtract(Duration(days: days, hours: hours, minutes: minutes));
  }

  // --- Identidad ---
  static AppUser user() => const AppUser(
        id: 'u_juan',
        name: 'Juan Pérez',
        email: 'juan@correo.com',
        avatarSeed: 7,
      );

  /// Perfil comprador que nace con toda cuenta nueva.
  static Profile buyerProfile() => const Profile(
        id: 'p_buyer',
        type: ProfileType.buyer,
        displayName: 'Juan',
        description: 'Comprando lo mejor de mi gente.',
      );

  /// Perfiles propios del usuario de demo (comprador + vendedores + servicios).
  static List<Profile> ownedProfiles() => [
        buyerProfile(),
        const Profile(
          id: 'p_esquina',
          type: ProfileType.seller,
          displayName: 'Tienda La Esquina',
          description: 'Abarrotes y café de especialidad.',
          category: 'Abarrotes',
          followers: 1243,
        ),
        const Profile(
          id: 'p_modajp',
          type: ProfileType.seller,
          displayName: 'Moda JP',
          description: 'Ropa urbana y accesorios.',
          category: 'Moda',
          followers: 864,
        ),
        const Profile(
          id: 'p_plomeria',
          type: ProfileType.service,
          displayName: 'Plomería Express',
          description: 'Reparaciones a domicilio 24/7.',
          category: 'Hogar',
          followers: 412,
        ),
      ];

  /// Tiendas externas que aparecen en Explorar / feed.
  static List<Profile> externalStores() => [
        const Profile(
          id: 'ext_tecnomax',
          type: ProfileType.seller,
          displayName: 'TecnoMax',
          description: 'Gadgets y tecnología al mejor precio.',
          category: 'Tecnología',
          followers: 15200,
          isOwnedByUser: false,
        ),
        const Profile(
          id: 'ext_dulcehogar',
          type: ProfileType.seller,
          displayName: 'Dulce Hogar',
          description: 'Todo para decorar tu espacio.',
          category: 'Hogar',
          followers: 7820,
          isOwnedByUser: false,
        ),
        const Profile(
          id: 'ext_fitlife',
          type: ProfileType.service,
          displayName: 'FitLife',
          description: 'Entrenamiento y bienestar personalizado.',
          category: 'Salud',
          followers: 5310,
          isOwnedByUser: false,
        ),
        const Profile(
          id: 'ext_gadgetpro',
          type: ProfileType.seller,
          displayName: 'GadgetPro',
          description: 'Accesorios para tus dispositivos.',
          category: 'Tecnología',
          followers: 2040,
          isOwnedByUser: false,
        ),
      ];

  /// Tiendas que el comprador sigue al inicio.
  static Set<String> followedStoreIds() =>
      {'ext_tecnomax', 'ext_dulcehogar', 'ext_fitlife'};

  // --- Publicaciones ---
  static List<Post> posts() => [
        Post(
          id: 'post_1',
          storeProfileId: 'ext_tecnomax',
          storeName: 'TecnoMax',
          storeType: ProfileType.seller,
          title: 'Audífonos inalámbricos X-Pro',
          body:
              'Cancelación de ruido activa, 30h de batería y estuche de carga rápida.',
          imageSeed: 11,
          price: 59.99,
          isPromoted: true,
          createdAt: _ago(hours: 2),
          reactionCounts: {ReactionType.like: 98, ReactionType.want: 24},
          commentCount: 3,
        ),
        Post(
          id: 'post_2',
          storeProfileId: 'ext_dulcehogar',
          storeName: 'Dulce Hogar',
          storeType: ProfileType.seller,
          title: 'Set de velas aromáticas',
          body: 'Lavanda, vainilla y cítricos. Hechas a mano con cera de soya.',
          imageSeed: 22,
          price: 12.50,
          createdAt: _ago(hours: 5),
          reactionCounts: {ReactionType.like: 45, ReactionType.love: 31},
          myReaction: ReactionType.love,
          commentCount: 2,
        ),
        Post(
          id: 'post_3',
          storeProfileId: 'ext_fitlife',
          storeName: 'FitLife',
          storeType: ProfileType.service,
          title: 'Rutina personalizada 1 mes',
          body: 'Plan de entrenamiento + nutrición adaptado a tu objetivo.',
          imageSeed: 33,
          price: 25.00,
          createdAt: _ago(hours: 8),
          reactionCounts: {ReactionType.like: 60, ReactionType.want: 12},
          commentCount: 1,
        ),
        Post(
          id: 'post_4',
          storeProfileId: 'ext_gadgetpro',
          storeName: 'GadgetPro',
          storeType: ProfileType.seller,
          title: 'Power bank 20,000 mAh',
          body: 'Carga tu teléfono hasta 4 veces. Dos puertos USB-C.',
          imageSeed: 44,
          price: 21.99,
          isPromoted: true,
          createdAt: _ago(hours: 12),
          reactionCounts: {ReactionType.like: 150, ReactionType.want: 40},
          commentCount: 0,
        ),
        Post(
          id: 'post_5',
          storeProfileId: 'ext_tecnomax',
          storeName: 'TecnoMax',
          storeType: ProfileType.seller,
          title: 'Teclado mecánico retroiluminado',
          body: 'Switches azules, RGB personalizable y reposamuñecas incluido.',
          imageSeed: 55,
          price: 45.00,
          createdAt: _ago(days: 1),
          reactionCounts: {ReactionType.like: 72},
          commentCount: 0,
        ),
        Post(
          id: 'post_6',
          storeProfileId: 'ext_dulcehogar',
          storeName: 'Dulce Hogar',
          storeType: ProfileType.seller,
          title: 'Juego de sábanas premium',
          body: 'Algodón 400 hilos, suavidad de hotel. Varias tallas y colores.',
          imageSeed: 66,
          price: 34.90,
          createdAt: _ago(days: 1, hours: 4),
          reactionCounts: {ReactionType.love: 54, ReactionType.want: 18},
          commentCount: 0,
        ),
        Post(
          id: 'post_7',
          storeProfileId: 'ext_fitlife',
          storeName: 'FitLife',
          storeType: ProfileType.service,
          title: 'Clase de yoga en línea',
          body: 'Sesión en vivo de 60 min para todos los niveles. Cupo limitado.',
          imageSeed: 77,
          price: 10.00,
          createdAt: _ago(days: 2),
          reactionCounts: {ReactionType.like: 33, ReactionType.love: 9},
          commentCount: 0,
        ),
        // Publicaciones de las tiendas propias del usuario (para demo CRUD).
        Post(
          id: 'post_8',
          storeProfileId: 'p_esquina',
          storeName: 'Tienda La Esquina',
          storeType: ProfileType.seller,
          title: 'Café de especialidad 250g',
          body: 'Tostado artesanal, origen único. Molido o en grano.',
          imageSeed: 88,
          price: 8.50,
          createdAt: _ago(days: 2, hours: 6),
          reactionCounts: {ReactionType.like: 21, ReactionType.want: 5},
          commentCount: 0,
        ),
        Post(
          id: 'post_9',
          storeProfileId: 'p_modajp',
          storeName: 'Moda JP',
          storeType: ProfileType.seller,
          title: 'Chaqueta de mezclilla',
          body: 'Corte unisex, edición limitada. Tallas S a XL.',
          imageSeed: 99,
          price: 39.99,
          createdAt: _ago(days: 3),
          reactionCounts: {ReactionType.love: 40, ReactionType.want: 15},
          commentCount: 0,
        ),
        Post(
          id: 'post_10',
          storeProfileId: 'p_plomeria',
          storeName: 'Plomería Express',
          storeType: ProfileType.service,
          title: 'Revisión y detección de fugas',
          body: 'Diagnóstico con equipo especializado. Sin costo de traslado.',
          imageSeed: 100,
          price: 20.00,
          createdAt: _ago(days: 3, hours: 5),
          reactionCounts: {ReactionType.like: 12},
          commentCount: 0,
        ),
      ];

  static Map<String, List<Comment>> comments() => {
        'post_1': [
          Comment(
            id: 'c1',
            postId: 'post_1',
            authorName: 'Ana López',
            authorAvatarSeed: 3,
            text: '¿Tienen disponibles en color blanco?',
            createdAt: _ago(hours: 1),
          ),
          Comment(
            id: 'c2',
            postId: 'post_1',
            authorName: 'Carlos M.',
            authorAvatarSeed: 5,
            text: 'Los compré y la batería es increíble 🔋',
            createdAt: _ago(minutes: 40),
          ),
          Comment(
            id: 'c3',
            postId: 'post_1',
            authorName: 'TecnoMax',
            authorAvatarSeed: 11,
            text: '¡Gracias por tu compra, Carlos!',
            createdAt: _ago(minutes: 20),
          ),
        ],
        'post_2': [
          Comment(
            id: 'c4',
            postId: 'post_2',
            authorName: 'Marta R.',
            authorAvatarSeed: 8,
            text: 'Huelen delicioso, totalmente recomendadas.',
            createdAt: _ago(hours: 3),
          ),
          Comment(
            id: 'c5',
            postId: 'post_2',
            authorName: 'Juan',
            authorAvatarSeed: 7,
            text: '¿Hacen envíos al centro?',
            createdAt: _ago(hours: 2),
            isMine: true,
          ),
        ],
        'post_3': [
          Comment(
            id: 'c6',
            postId: 'post_3',
            authorName: 'Diego S.',
            authorAvatarSeed: 2,
            text: '¿Incluye seguimiento semanal?',
            createdAt: _ago(hours: 6),
          ),
        ],
      };

  // --- Chat ---
  static List<Conversation> conversations() => [
        Conversation(
          id: 'conv_1',
          storeProfileId: 'ext_tecnomax',
          storeName: 'TecnoMax',
          storeType: ProfileType.seller,
          lastMessage: '¡Claro! Tenemos stock disponible.',
          lastTime: _ago(hours: 1),
          unread: 2,
        ),
        Conversation(
          id: 'conv_2',
          storeProfileId: 'ext_dulcehogar',
          storeName: 'Dulce Hogar',
          storeType: ProfileType.seller,
          lastMessage: 'Gracias por tu compra 😊',
          lastTime: _ago(days: 1),
        ),
        Conversation(
          id: 'conv_3',
          storeProfileId: 'ext_fitlife',
          storeName: 'FitLife',
          storeType: ProfileType.service,
          lastMessage: 'Tu rutina está lista para descargar.',
          lastTime: _ago(days: 2),
        ),
      ];

  static Map<String, List<Message>> messages() => {
        'conv_1': [
          Message(
            id: 'm1',
            conversationId: 'conv_1',
            text: 'Hola, ¿los audífonos X-Pro siguen disponibles?',
            isMine: true,
            time: _ago(hours: 1, minutes: 10),
          ),
          Message(
            id: 'm2',
            conversationId: 'conv_1',
            text: '¡Claro! Tenemos stock disponible.',
            isMine: false,
            time: _ago(hours: 1),
          ),
        ],
        'conv_2': [
          Message(
            id: 'm3',
            conversationId: 'conv_2',
            text: 'Me encantaron las velas, gracias.',
            isMine: true,
            time: _ago(days: 1, hours: 1),
          ),
          Message(
            id: 'm4',
            conversationId: 'conv_2',
            text: 'Gracias por tu compra 😊',
            isMine: false,
            time: _ago(days: 1),
          ),
        ],
        'conv_3': [
          Message(
            id: 'm5',
            conversationId: 'conv_3',
            text: 'Tu rutina está lista para descargar.',
            isMine: false,
            time: _ago(days: 2),
          ),
        ],
      };
}
