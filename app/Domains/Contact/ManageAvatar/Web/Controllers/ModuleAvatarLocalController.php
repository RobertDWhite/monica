<?php

namespace App\Domains\Contact\ManageAvatar\Web\Controllers;

use App\Domains\Contact\ManageAvatar\Services\UpdatePhotoAsAvatar;
use App\Http\Controllers\Controller;
use App\Models\File;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ModuleAvatarLocalController extends Controller
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $request->validate([
            'photo' => 'required|image|max:10240',
        ]);

        $uploaded = $request->file('photo');
        $path = $uploaded->store('contact-avatars', 'public');

        $file = File::create([
            'vault_id' => $vaultId,
            'uuid' => (string) Str::uuid(),
            'original_url' => Storage::disk('public')->url($path),
            'cdn_url' => Storage::disk('public')->url($path),
            'mime_type' => $uploaded->getMimeType(),
            'name' => $uploaded->getClientOriginalName(),
            'type' => File::TYPE_AVATAR,
            'size' => $uploaded->getSize(),
        ]);

        (new UpdatePhotoAsAvatar)->execute([
            'account_id' => Auth::user()->account_id,
            'author_id' => Auth::id(),
            'vault_id' => $vaultId,
            'contact_id' => $contactId,
            'file_id' => $file->id,
        ]);

        return response()->json([
            'data' => route('contact.show', [
                'vault' => $vaultId,
                'contact' => $contactId,
            ]),
        ], 200);
    }
}
