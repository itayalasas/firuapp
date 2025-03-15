const { onValueWritten } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

// 🔹 Webhook para actualizar los likes en Firestore cuando cambian en Realtime Database
exports.syncLikesWithFirestore = onValueWritten("/likes/{photoId}/{userId}", async (event) => {
    const photoId = event.params.photoId;
    const likesRef = admin.database().ref(`/likes/${photoId}`);

    try {
        // 🔍 Contar la cantidad de likes actuales
        const snapshot = await likesRef.once("value");
        const newLikeCount = snapshot.numChildren();

        // 🔍 Obtener el conteo actual en Firestore
        const photoRef = admin.firestore().collection("photos").doc(photoId);
        const photoDoc = await photoRef.get();
        const currentLikeCount = photoDoc.exists ? (photoDoc.data().likeCount || 0) : 0;

        // 🔄 Solo actualizar si el conteo de likes cambió
        if (newLikeCount !== currentLikeCount) {
            await photoRef.update({
                likeCount: newLikeCount,
            });
            console.log(`✅ Like actualizado para la foto ${photoId}: ${newLikeCount} likes`);
        } else {
            console.log(`ℹ️ No se realizaron cambios para la foto ${photoId}`);
        }
    } catch (error) {
        console.error("❌ Error actualizando likes en Firestore:", error);
    }
});

// 🔹 Endpoint para verificar el correo y actualizar el estado del usuario
exports.verifyUserEmail = functions.https.onRequest(async (req, res) => {
    const userId = req.query.userId; // Obtener el ID del usuario desde la URL

    if (!userId) {
        return res.status(400).send("Falta el parámetro userId.");
    }

    try {
        await admin.firestore().collection("users").doc(userId).update({
            state: 2, // Cambiar estado de 1 a 2
        });
        const errorHtml =
    "<html lang='en'>" +
    "<head>" +
    "<meta charset='UTF-8'>" +
    "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" +
    "<title>Confirmación Exitosa</title>" +
    "<style>" +
    "body { font-family: Arial, sans-serif; margin: 20px; text-align: center; " +
    "background-color: #f3f3f3; }" +
    ".container { max-width: 600px; margin: 0 auto; padding: 20px; border-radius: 5px; " +
    "background-color: #ffffff; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }" +
    ".icon { font-size: 60px; color: #28a745; }" +
    "h2 { color: #28a745; margin-bottom: 10px; }" +
    "p { margin-bottom: 20px; }" +
    ".btn { display: inline-block; font-weight: 400; color: #ffffff; text-align: center; " +
    "vertical-align: middle; user-select: none; background-color: #007bff; border: 1px solid transparent; " +
    "padding: 10px 20px; font-size: 1rem; line-height: 1.5; border-radius: 5px; text-decoration: none; }" +
    ".btn:hover { background-color: #0056b3; color: #ffffff; }" +
    "</style>" +
    "</head>" +
    "<body>" +
    "<div class='container'>" +
    "<span class='icon'>&#10003;</span>" +
    "<h2>Confirmación Exitosa</h2>" +
    "<p>Su cuenta ha sido confirmada con éxito. ¡Gracias por ser parte de PetCare+!</p>" +
    "</div>" +
    "</body>" +
    "</html>";
        return res.status(200).send(errorHtml);
    } catch (error) {
        console.error("❌ Error al actualizar el estado del usuario:", error);
        return res.status(500).send("❌ Error al verificar el correo.");
    }
});
