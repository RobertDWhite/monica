<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManagePets\Services\CreatePet;
use App\Domains\Contact\ManagePets\Services\DestroyPet;
use App\Domains\Contact\ManagePets\Services\UpdatePet;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Pets
 */
class ContactPetApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new CreatePet)->execute($this->baseData($request, $vaultId, $contactId) + [
            'pet_category_id' => $request->input('pet_category_id'),
            'name' => $request->input('name'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function update(Request $request, string $vaultId, string $contactId, string $petId)
    {
        (new UpdatePet)->execute($this->baseData($request, $vaultId, $contactId) + [
            'pet_id' => (int) $petId,
            'pet_category_id' => $request->input('pet_category_id'),
            'name' => $request->input('name'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $petId)
    {
        (new DestroyPet)->execute($this->baseData($request, $vaultId, $contactId) + [
            'pet_id' => (int) $petId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
